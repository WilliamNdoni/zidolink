defmodule ZidolinkWeb.ClientProfileLive.Edit do
  use ZidolinkWeb, :live_view

  alias Zidolink.Profiles
  alias Zidolink.Profiles.ClientProfile

  @activity_levels [
    {"sedentary", "Sedentary", "Desk job"},
    {"light", "Lightly Active", "Mostly on your feet at work"},
    {"moderate", "Moderately Active", "Active job (nurse, police, etc.)"},
    {"active", "Very Active", "Very physical job"},
    {"very_active", "Extremely Active", "Athlete, very physical job"}
  ]

  @activity_labels %{
    "sedentary" => "Sedentary",
    "light" => "Lightly Active",
    "moderate" => "Moderately Active",
    "active" => "Very Active",
    "very_active" => "Extremely Active"
  }

  @gender_labels %{"male" => "Male", "female" => "Female", "other" => "Prefer not to say"}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.header>Your profile</.header>

        <%= if @editing do %>
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

            <div class="divider" />

            <.input
              field={@form[:goal_text]}
              type="textarea"
              label="Your fitness goal"
              placeholder="e.g. Lose 5kg before December, build lean muscle, improve 10k run time"
            />
            <p class="text-xs text-base-content/60 -mt-2 mb-3">Up to 150 words.</p>
            <label class="label mb-1">Target weight</label>
            <div class="flex gap-2 mb-2">
              <input
                type="number"
                step="0.1"
                name="target_weight_value"
                value={@target_weight_value}
                class="input input-bordered w-28"
                placeholder={if @target_weight_unit == "kg", do: "e.g. 70", else: "e.g. 154"}
              />
              <button
                type="button"
                phx-click="switch_target_weight_unit"
                phx-value-unit="kg"
                class={unit_class(@target_weight_unit, "kg")}
              >
                kg
              </button>
              <button
                type="button"
                phx-click="switch_target_weight_unit"
                phx-value-unit="lbs"
                class={unit_class(@target_weight_unit, "lbs")}
              >
                lbs
              </button>
            </div>

            <div class="divider" />

            <label class="label mb-1">Height</label>
            <div class="flex gap-2 mb-2">
              <button
                type="button"
                phx-click="switch_height_unit"
                phx-value-unit="cm"
                class={unit_class(@height_unit, "cm")}
              >
                cm
              </button>
              <button
                type="button"
                phx-click="switch_height_unit"
                phx-value-unit="ft_in"
                class={unit_class(@height_unit, "ft_in")}
              >
                ft
              </button>
            </div>

            <%= if @height_unit == "cm" do %>
              <.input field={@form[:height_cm]} type="number" step="0.1" />
            <% else %>
              <div class="flex gap-2">
                <div class="flex-1">
                  <label class="label text-xs">Feet</label>
                  <input type="number" name="height_ft" value={@height_ft} class="input input-bordered w-full" />
                </div>
                <div class="flex-1">
                  <label class="label text-xs">Inches</label>
                  <input type="number" name="height_in" value={@height_in} class="input input-bordered w-full" />
                </div>
              </div>
            <% end %>

            <div class="divider" />

            <.input field={@form[:age]} type="number" label="Age" />

            <label class="label mb-1">Gender</label>
            <div class="flex gap-2 mb-2 flex-wrap">
              <button
                :for={{value, label} <- [{"male", "Male"}, {"female", "Female"}, {"other", "Prefer not to say"}]}
                type="button"
                phx-click="set_gender"
                phx-value-gender={value}
                class={unit_class(@gender, value)}
              >
                {label}
              </button>
            </div>
            <input type="hidden" name="client_profile[gender]" value={@gender} />

            <div class="divider" />

            <label class="label mb-1">Activity Level</label>
            <div class="flex flex-col gap-2">
              <label
                :for={{value, title, description} <- @activity_levels}
                class={"flex items-start gap-2 border rounded-lg p-3 cursor-pointer #{if @activity_level == value, do: "border-primary bg-primary/5", else: "border-base-300"}"}
              >
                <input
                  type="radio"
                  name="activity_level_radio"
                  value={value}
                  checked={@activity_level == value}
                  phx-click="set_activity_level"
                  phx-value-level={value}
                  class="radio radio-sm radio-primary mt-0.5"
                />
                <div>
                  <p class="font-medium text-sm">{title}</p>
                  <p class="text-xs text-base-content/60">{description}</p>
                </div>
              </label>
            </div>
            <input type="hidden" name="client_profile[activity_level]" value={@activity_level} />

            <div class="flex gap-2 mt-6">
              <.button phx-disable-with="Saving..." class="btn btn-primary flex-1">
                Save Profile
              </.button>
              <.button type="button" phx-click="cancel_edit" class="btn btn-outline">Cancel</.button>
            </div>
          </.form>
        <% else %>
          <p :if={@incomplete} class="text-sm text-warning border border-warning rounded-lg p-3 mt-2">
            Your profile is incomplete. Trainers use these details to personalize your training, fill them in so they can help you better.
          </p>

          <div class="rounded-lg p-4 mt-4 border border-base-300 bg-base-200">
            <h3 class="font-semibold text-sm mb-2">Account</h3>
            <div class="text-sm space-y-1">
              <p><span class="text-base-content/60">Display name:</span> {val(@profile.display_name)}</p>
              <p>
                <span class="text-base-content/60">Phone visible to trainers:</span>
                {if @profile.phone_visible_to_trainers, do: "Yes", else: "No"}
              </p>
            </div>
          </div>

          <div class="rounded-lg p-4 mt-3 border border-[#0E7C5D]/30 bg-[#0E7C5D]/10">
            <h3 class="font-semibold text-sm mb-2 text-[#0E7C5D]">Goal</h3>
            <div class="text-sm space-y-1">
              <p><span class="text-base-content/60">Fitness goal:</span> {val(@profile.goal_text)}</p>
              <p>
                <span class="text-base-content/60">Target weight:</span>
                {if @profile.target_weight_kg, do: "#{@profile.target_weight_kg} kg", else: "Not set yet"}
              </p>
            </div>
          </div>

          <div class="rounded-lg p-4 mt-3 border border-[#8B7AB8]/30 bg-[#8B7AB8]/10">
            <h3 class="font-semibold text-sm mb-2 text-[#8B7AB8]">Body details</h3>
            <div class="text-sm space-y-1">
              <p>
                <span class="text-base-content/60">Height:</span>
                {if @profile.height_cm, do: "#{@profile.height_cm} cm", else: "Not set yet"}
              </p>
              <p><span class="text-base-content/60">Age:</span> {val(@profile.age)}</p>
              <p><span class="text-base-content/60">Gender:</span> {gender_label(@profile.gender)}</p>
              <p><span class="text-base-content/60">Activity level:</span> {activity_label(@profile.activity_level)}</p>
            </div>
          </div>

          <.button phx-click="start_edit" class="btn btn-primary w-full mt-4">Update Profile</.button>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile = Profiles.get_or_build_client_profile(user.id)

    {:ok,
     assign(socket,
       profile: profile,
       editing: false,
       incomplete: profile_incomplete?(profile),
       form: build_form(profile),
       height_unit: "cm",
       height_ft: nil,
       height_in: nil,
       target_weight_unit: "kg",
       target_weight_value: profile.target_weight_kg,
       gender: profile.gender,
       activity_level: profile.activity_level,
       activity_levels: @activity_levels
     )}
  end

  @impl true
  def handle_event("start_edit", _params, socket) do
    {:noreply, assign(socket, editing: true)}
  end

  def handle_event("cancel_edit", _params, socket) do
    profile = socket.assigns.profile

    {:noreply,
     assign(socket,
       editing: false,
       form: build_form(profile),
       height_unit: "cm",
       height_ft: nil,
       height_in: nil,
       target_weight_unit: "kg",
       target_weight_value: profile.target_weight_kg,
       gender: profile.gender,
       activity_level: profile.activity_level
     )}
  end

  def handle_event("switch_height_unit", %{"unit" => unit}, socket) do
    {:noreply, assign(socket, height_unit: unit)}
  end

  def handle_event("switch_target_weight_unit", %{"unit" => unit}, socket) do
    {:noreply, assign(socket, target_weight_unit: unit)}
  end

  def handle_event("set_gender", %{"gender" => gender}, socket) do
    {:noreply, assign(socket, gender: gender)}
  end

  def handle_event("set_activity_level", %{"level" => level}, socket) do
    {:noreply, assign(socket, activity_level: level)}
  end

  def handle_event("validate", params, socket) do
    client_profile_params =
      merge_height(params, socket.assigns.height_unit)
      |> merge_target_weight(params, socket.assigns.target_weight_unit)
      |> Map.put("gender", socket.assigns.gender)
      |> Map.put("activity_level", socket.assigns.activity_level)

    changeset =
      socket.assigns.profile
      |> ClientProfile.changeset(client_profile_params)
      |> Map.put(:action, :validate)

    {:noreply,
     assign(socket,
       form: to_form(changeset),
       height_ft: params["height_ft"] || socket.assigns.height_ft,
       height_in: params["height_in"] || socket.assigns.height_in,
       target_weight_value: params["target_weight_value"] || socket.assigns.target_weight_value
     )}
  end

  def handle_event("save", params, socket) do
    profile = socket.assigns.profile

    client_profile_params =
      merge_height(params, socket.assigns.height_unit)
      |> merge_target_weight(params, socket.assigns.target_weight_unit)
      |> Map.put("gender", socket.assigns.gender)
      |> Map.put("activity_level", socket.assigns.activity_level)

    result =
      if profile.id do
        Profiles.update_client_profile(profile, client_profile_params)
      else
        Profiles.create_client_profile(Map.put(client_profile_params, "user_id", socket.assigns.current_scope.user.id))
      end

    case result do
      {:ok, updated_profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile saved.")
         |> assign(
           profile: updated_profile,
           editing: false,
           incomplete: profile_incomplete?(updated_profile),
           form: build_form(updated_profile),
           gender: updated_profile.gender,
           activity_level: updated_profile.activity_level
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp build_form(profile), do: to_form(ClientProfile.changeset(profile, %{}))

  defp profile_incomplete?(profile) do
    is_nil(profile.goal_text) or is_nil(profile.target_weight_kg) or is_nil(profile.height_cm) or
      is_nil(profile.age) or is_nil(profile.gender) or is_nil(profile.activity_level)
  end

  defp merge_height(%{"client_profile" => cp_params} = params, "ft_in") do
    feet = parse_float(params["height_ft"])
    inches = parse_float(params["height_in"])

    cm =
      if feet || inches do
        Float.round((feet || 0) * 30.48 + (inches || 0) * 2.54, 1)
      end

    if cm, do: Map.put(cp_params, "height_cm", cm), else: cp_params
  end

  defp merge_height(%{"client_profile" => cp_params}, _unit) do
    case cp_params["height_cm"] do
      nil ->
        cp_params

      "" ->
        cp_params

      str ->
        case parse_float(str) do
          nil -> cp_params
          val -> Map.put(cp_params, "height_cm", Float.round(val, 1))
        end
    end
  end
  defp merge_height(_params, _unit), do: %{}

  defp merge_target_weight(cp_params, params, "lbs") do
    case parse_float(params["target_weight_value"]) do
      nil -> cp_params
      val -> Map.put(cp_params, "target_weight_kg", Float.round(val * 0.453592, 1))
    end
  end

  defp merge_target_weight(cp_params, params, _kg) do
    case parse_float(params["target_weight_value"]) do
      nil -> cp_params
      val -> Map.put(cp_params, "target_weight_kg", Float.round(val, 1))
    end
  end

  defp parse_float(nil), do: nil
  defp parse_float(""), do: nil

  defp parse_float(str) do
    case Float.parse(str) do
      {val, _} -> val
      :error -> nil
    end
  end

  defp unit_class(current, key) when current == key, do: "btn btn-primary btn-sm"
  defp unit_class(_current, _key), do: "btn btn-outline btn-sm"

  defp val(nil), do: "Not set yet"
  defp val(""), do: "Not set yet"
  defp val(value), do: value

  defp gender_label(nil), do: "Not set yet"
  defp gender_label(value), do: Map.get(@gender_labels, value, value)

  defp activity_label(nil), do: "Not set yet"
  defp activity_label(value), do: Map.get(@activity_labels, value, value)
end
