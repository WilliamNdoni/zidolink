defmodule ZidolinkWeb.ClientProfileLive.Edit do
  use ZidolinkWeb, :live_view

  alias Zidolink.Profiles
  alias Zidolink.Profiles.ClientProfile

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.header>Your profile</.header>

        <.form for={@form} id="client_profile_form" phx-submit="save" phx-change="validate" novalidate>
          <.input field={@form[:display_name]} type="text" label="Display name (optional)" />
          <p class="text-sm text-base-content/60 -mt-2 mb-3">
            Shown to trainers you contact, instead of just your email.
          </p>

          <.input
            field={@form[:phone_visible_to_trainers]}
            type="checkbox"
            label="Let trainers see my phone number"
          />

          <.button phx-disable-with="Saving..." class="btn btn-primary w-full mt-4">
            Save
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile = Profiles.get_or_build_client_profile(user.id)
    changeset = ClientProfile.changeset(profile, %{})
    {:ok, assign(socket, form: to_form(changeset), profile: profile)}
  end

  @impl true
  def handle_event("validate", %{"client_profile" => params}, socket) do
    changeset =
      socket.assigns.profile
      |> ClientProfile.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"client_profile" => params}, socket) do
    profile = socket.assigns.profile

    result =
      if profile.id do
        Profiles.update_client_profile(profile, params)
      else
        Profiles.create_client_profile(Map.put(params, "user_id", socket.assigns.current_scope.user.id))
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
end
