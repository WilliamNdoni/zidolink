defmodule ZidolinkWeb.TrainerClientLive.Show do
  use ZidolinkWeb, :live_view

  alias Zidolink.{Profiles, Subscriptions, Accounts, Avatars}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div :if={@not_found} class="mx-auto max-w-lg text-center mt-8">
        <.header>No relationship found</.header>
        <p class="text-sm text-base-content/80 mt-2">
          This client has no subscription history with you.
        </p>
        <.link href={~p"/trainer/clients"} class="btn btn-primary btn-sm mt-4">Back to Clients</.link>
      </div>

      <div :if={!@not_found} class="mx-auto max-w-2xl">
        <div class="flex items-center gap-3">
          <div
            class="flex-none size-14 rounded-full flex items-center justify-center font-bold text-base"
            style={"background-color: #{@avatar_bg}; color: #{@avatar_fg}"}
          >
            {@initials}
          </div>
          <div>
            <h1 class="text-lg font-semibold">{@label}</h1>
            <p :if={@label != @client.email} class="text-sm text-base-content/60">{@client.email}</p>
            <p :if={@phone} class="text-sm text-base-content/60">{@phone}</p>
          </div>
        </div>

        <div class="border rounded-lg p-4 mt-4">
          <div class="flex items-center justify-between mb-2">
            <h3 class="font-semibold text-sm">Subscription</h3>
            <span class={status_badge_class(@subscription.status)}>
              {String.capitalize(@subscription.status)}
            </span>
          </div>
          <p class="text-sm text-base-content/60 mb-3">
            {String.capitalize(@subscription.kind)} plan
          </p>

          <div class="flex flex-col sm:flex-row sm:items-center gap-2 py-2 border-b border-base-200">
            <%= if @editing_rate do %>
              <form phx-submit="update_rate" class="flex flex-wrap items-end gap-2 w-full">
                <div>
                  <label class="label text-xs">Rate (KES)</label>
                  <input type="number" name="price" value={@subscription.price} class="input input-bordered input-sm w-28" autofocus />
                </div>
                <.button class="btn btn-primary btn-sm">Save</.button>
                <.button type="button" phx-click="cancel_edit_rate" class="btn btn-outline btn-sm">Cancel</.button>
              </form>
            <% else %>
              <p class="text-sm flex-1">Rate: KES {@subscription.price}</p>
              <.button phx-click="edit_rate" class="btn btn-primary btn-sm">Edit Rate</.button>
            <% end %>
          </div>

          <div class="flex flex-col sm:flex-row sm:items-center gap-2 py-2">
            <%= if @editing_due_date do %>
              <form phx-submit="update_due_date" class="flex flex-wrap items-end gap-2 w-full">
                <div>
                  <label class="label text-xs">Due date</label>
                  <input type="date" name="ends_at" value={@ends_at_date} class="input input-bordered input-sm" autofocus />
                </div>
                <.button class="btn btn-primary btn-sm">Save</.button>
                <.button type="button" phx-click="cancel_edit_due_date" class="btn btn-outline btn-sm">Cancel</.button>
              </form>
            <% else %>
              <p class="text-sm flex-1">
                Due: {if @subscription.ends_at, do: Calendar.strftime(@subscription.ends_at, "%d %b %Y"), else: "Not set"}
              </p>
              <.button phx-click="edit_due_date" class="btn btn-primary btn-sm">Edit Due Date</.button>
            <% end %>
          </div>
        </div>

        <div class="border rounded-lg p-4 mt-4">
          <h3 class="font-semibold text-sm mb-2">Goal</h3>
          <p class="text-sm text-base-content/80">
            {@client_profile.goal_text || "No goal set by client yet."}
          </p>
          <p :if={@client_profile.target_weight_kg} class="text-sm text-base-content/80 mt-1">
            Target weight: {@client_profile.target_weight_kg} kg
          </p>
        </div>

        <div class="border rounded-lg p-4 mt-4">
          <h3 class="font-semibold text-sm mb-2">Profile</h3>
          <div class="text-sm text-base-content/80 space-y-1">
            <p :if={@client_profile.height_cm}>Height: {@client_profile.height_cm} cm</p>
            <p :if={@client_profile.age}>Age: {@client_profile.age}</p>
            <p :if={@client_profile.gender}>Gender: {String.capitalize(@client_profile.gender)}</p>
            <p :if={@client_profile.activity_level}>
              Activity level: {String.capitalize(String.replace(@client_profile.activity_level, "_", " "))}
            </p>
            <p :if={!@client_profile.height_cm && !@client_profile.age} class="text-base-content/60">
              Client hasn't filled in their profile details yet.
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => client_id}, _session, socket) do
    trainer = socket.assigns.current_scope.user
    client = Accounts.get_user!(client_id)
    subscription = Subscriptions.get_current_subscription(client.id, trainer.id)

    if subscription do
      client_profile = Profiles.get_or_build_client_profile(client.id)
      label = Avatars.label(client_profile.display_name, client.email)
      {bg, fg} = Avatars.color(label)

      {:ok,
       assign(socket,
         not_found: false,
         client: client,
         subscription: subscription,
         client_profile: client_profile,
         label: label,
         initials: Avatars.initials(client_profile.display_name, client.email),
         avatar_bg: bg,
         avatar_fg: fg,
         phone: (client_profile.phone_visible_to_trainers && client.phone) || nil,
         editing_rate: false,
         editing_due_date: false,
         ends_at_date: subscription.ends_at && Date.to_iso8601(DateTime.to_date(subscription.ends_at))
       )}
    else
      {:ok, assign(socket, not_found: true)}
    end
  end

  @impl true
  def handle_event("edit_rate", _params, socket), do: {:noreply, assign(socket, editing_rate: true)}
  def handle_event("cancel_edit_rate", _params, socket), do: {:noreply, assign(socket, editing_rate: false)}
  def handle_event("edit_due_date", _params, socket), do: {:noreply, assign(socket, editing_due_date: true)}
  def handle_event("cancel_edit_due_date", _params, socket), do: {:noreply, assign(socket, editing_due_date: false)}

  def handle_event("update_rate", %{"price" => price}, socket) do
    case Subscriptions.update_subscription(socket.assigns.subscription, %{price: String.to_integer(price)}) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rate updated.")
         |> assign(subscription: updated, editing_rate: false)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Couldn't update the rate — please check the value.")}
    end
  end

  def handle_event("update_due_date", %{"ends_at" => ends_at}, socket) do
    case Date.from_iso8601(ends_at) do
      {:ok, date} ->
        new_ends_at = DateTime.new!(date, ~T[23:59:59])

        case Subscriptions.update_subscription(socket.assigns.subscription, %{ends_at: new_ends_at}) do
          {:ok, updated} ->
            {:noreply,
             socket
             |> put_flash(:info, "Due date updated.")
             |> assign(
               subscription: updated,
               ends_at_date: Date.to_iso8601(date),
               editing_due_date: false
             )}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Couldn't update the due date.")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Please enter a valid date.")}
    end
  end

  defp status_badge_class("active"), do: "badge badge-success"
  defp status_badge_class("expired"), do: "badge badge-error"
  defp status_badge_class("cancelled"), do: "badge badge-ghost"
  defp status_badge_class(_), do: "badge badge-ghost"
end
