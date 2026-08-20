defmodule ZidolinkWeb.TrainerProfileLive.Edit do
  use ZidolinkWeb, :live_view

  alias Zidolink.Profiles
  alias Zidolink.Profiles.TrainerProfile

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <.header>
          Set up your trainer profile
          <:subtitle>This is what clients will see when they find you.</:subtitle>
        </.header>

        <.form for={@form} id="trainer_profile_form" phx-submit="save" phx-change="validate">
          <.input field={@form[:display_name]} type="text" label="Display name" />
          <.input field={@form[:bio]} type="textarea" label="Bio" required />
          <input
            type="text"
            name="trainer_profile[specialties_text]"
            value={@specialties_text}
            placeholder="e.g. weight loss, strength training"
            class="w-full input"
          />
          <label class="label mb-1">Specialties (comma separated)</label>

          <div class="mt-4">
            <label class="label">Profile photo or logo</label>
            <.live_file_input upload={@uploads.photo} class="file-input file-input-bordered w-full" />
            <div :for={entry <- @uploads.photo.entries} class="mt-2 text-sm flex items-center gap-2">
              {entry.client_name}
              <progress class="progress progress-primary w-24" value={entry.progress} max="100"></progress>
            </div>
            <p :for={err <- upload_errors(@uploads.photo)} class="text-error text-sm mt-1">
              {photo_error_to_string(err)}
            </p>
            <img :if={@photo_url} src={@photo_url} class="mt-2 size-24 rounded-full object-cover" />
          </div>

          <div class="mt-4">
            <label class="label">Location</label>
            <div id="location-picker" phx-hook="LocationPicker" data-api-key={@google_maps_api_key} class="relative">
              <input
                type="text"
                id="location-search-input"
                placeholder="Search for your training location..."
                class="input input-bordered w-full"
                autocomplete="off"
                value={@location_address}
              />
              <ul
                id="location-results"
                class="absolute z-10 w-full bg-base-100 border border-base-300 rounded-lg mt-1 shadow-lg"
              >
              </ul>
              <button type="button" id="use-current-location" class="btn btn-secondary btn-sm mt-3">
                Use my current location
              </button>
              <p class="text-xs text-base-content/80 mt-1">
                On a laptop or desktop, typing your location in the search box above is usually more accurate than this button.
              </p>
            </div>
            <p :if={@form[:location_lat].value not in [nil, ""]} class="text-sm text-base-content/80 mt-2 flex items-center gap-1">
              <.icon name="hero-map-pin" class="size-4" />
              <%= if @form[:location_address].value not in [nil, ""] do %>
                {@form[:location_address].value}
              <% else %>
                Location set ({@form[:location_lat].value}, {@form[:location_lng].value})
              <% end %>
            </p>
          </div>

          <.input
            type="hidden"
            name="trainer_profile[location_lat]"
            value={@form[:location_lat].value}
          />
          <.input
            type="hidden"
            name="trainer_profile[location_lng]"
            value={@form[:location_lng].value}
          />

          <.button phx-disable-with="Saving..." class="btn btn-primary w-full mt-6">
            Save profile
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile = Profiles.get_or_build_trainer_profile(user.id)

    initial_attrs =
      if profile.id do
        %{}
      else
        application = Zidolink.RoleApplications.get_latest_application(user.id)
        app_data = (application && application.data) || %{}

        %{
          "display_name" => app_data["display_name"],
          "bio" => app_data["bio"]
        }
      end

    changeset = TrainerProfile.changeset(profile, initial_attrs)

    socket =
      allow_upload(socket, :photo,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 8_000_000,
        auto_upload: false
      )

    {:ok,
     assign(socket,
       form: to_form(changeset),
       profile: profile,
       photo_url: profile.photo_url,
       location_address: nil,
       specialties_text: Enum.join(profile.specialties || [], ", "),
       google_maps_api_key: System.get_env("GOOGLE_MAPS_API_KEY")
     )}
  end

  @impl true
  def handle_event("validate", %{"trainer_profile" => params}, socket) do
    changeset =
      socket.assigns.profile
      |> TrainerProfile.changeset(Map.drop(params, ["specialties_text"]))
      |> Map.put(:action, :validate)

    {:noreply,
     assign(socket,
       form: to_form(changeset),
       specialties_text: params["specialties_text"] || socket.assigns.specialties_text
     )}
  end

  def handle_event("location_selected", params, socket) do
    form_params =
      socket.assigns.form.params
      |> Map.put("location_lat", params["lat"])
      |> Map.put("location_lng", params["lng"])
      |> Map.put("location_address", params["address"])

    changeset =
      socket.assigns.profile
      |> TrainerProfile.changeset(form_params)
      |> Map.put(:action, :validate)

    {:noreply,
     assign(socket,
       form: to_form(changeset),
       location_address: params["address"]
     )}
  end

  def handle_event("save", %{"trainer_profile" => params}, socket) do
    photo_urls =
      consume_uploaded_entries(socket, :photo, fn %{path: path}, entry ->
        case Zidolink.Media.Cloudinary.upload(path, entry.client_name) do
          {:ok, %{"secure_url" => url}} -> {:ok, url}
          {:error, _reason} -> {:ok, nil}
        end
      end)

    params =
      case photo_urls do
        [url] when is_binary(url) -> Map.put(params, "photo_url", url)
        _ -> params
      end

    params =
      params
      |> Map.put("specialties", normalize_specialties_text(params["specialties_text"]))
      |> Map.put("profile_completed", true)

    save_profile(socket, params)
  end

  defp save_profile(socket, params) do
    profile = socket.assigns.profile

    result =
      if profile.id do
        Profiles.update_trainer_profile(profile, params)
      else
        Profiles.create_trainer_profile(Map.put(params, "user_id", socket.assigns.current_scope.user.id))
      end

    case result do
      {:ok, _profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile saved.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp normalize_specialties_text(nil), do: []
  defp normalize_specialties_text(""), do: []

  defp normalize_specialties_text(str) do
    str |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end
  defp photo_error_to_string(:too_large), do: "Photo is too large (max 8MB)"
  defp photo_error_to_string(:not_accepted), do: "Only JPG and PNG images are accepted"
  defp photo_error_to_string(:too_many_files), do: "Only one photo allowed"

end
