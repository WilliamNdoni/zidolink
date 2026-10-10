defmodule ZidolinkWeb.ClientRequestLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.{Subscriptions, Profiles, Avatars}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header>My Requests</.header>

        <div :if={@items == []} class="mt-6 text-center text-base-content/80">
          You haven't requested a subscription with any trainer yet.
        </div>

        <.link
          :for={item <- @items}
          navigate={~p"/trainers/#{item.trainer_profile_id}"}
          class={"mt-4 border rounded-lg p-4 block hover:shadow-md transition-shadow border-l-4 #{border_class(item.sub.status)}"}
        >
          <div class="flex gap-3 items-start">
            <img
              :if={item.photo_url}
              src={item.photo_url}
              class="flex-none size-12 rounded-full object-cover"
            />
            <div
              :if={!item.photo_url}
              class="flex-none size-12 rounded-full flex items-center justify-center font-bold text-sm"
              style={"background-color: #{item.avatar_bg}; color: #{item.avatar_fg}"}
            >
              {item.initials}
            </div>

            <div class="flex-1 min-w-0">
              <div class="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-2">
                <div>
                  <p class="font-semibold">{item.trainer_label}</p>
                  <p class="text-sm text-base-content/60">{String.capitalize(item.sub.kind)} subscription</p>
                  <p :if={item.location_address} class="text-sm text-base-content/60 flex items-center gap-1">
                    <.icon name="hero-map-pin" class="size-3.5" /> {item.location_address}
                  </p>
                </div>
                <span class={badge_class(item.sub.status)}>{status_label(item.sub.status)}</span>
              </div>

              <div :if={item.specialties != []} class="flex flex-wrap gap-1 mt-2">
                <span :for={s <- item.specialties} class="badge badge-outline badge-sm">{s}</span>
              </div>

              <div class="mt-2 text-sm text-base-content/80">
                <p :if={item.sub.price}>Quoted KES {item.sub.price}</p>
                <p :if={item.sub.status == "declined" && item.sub.decline_reason}>
                  You declined ({item.sub.decline_reason})
                </p>
                <p class="text-xs text-base-content/60">
                  Updated {Calendar.strftime(item.sub.updated_at, "%d %b %Y")}
                </p>
              </div>
            </div>
          </div>
        </.link>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    items = load_items(user.id)

    if connected?(socket) do
      Enum.each(items, fn item ->
        Phoenix.PubSub.subscribe(
          Zidolink.PubSub,
          Subscriptions.subscription_topic(user.id, item.sub.trainer_id)
        )
      end)
    end

    {:ok, assign(socket, items: items)}
  end

  @impl true
  def handle_info({:subscription_updated, _updated}, socket) do
    user = socket.assigns.current_scope.user
    {:noreply, assign(socket, items: load_items(user.id))}
  end

  defp load_items(client_id) do
    Subscriptions.list_requests_for_client(client_id)
    |> Enum.map(fn sub ->
      trainer_profile = Profiles.get_trainer_profile_by_user_id(sub.trainer_id)
      label = Avatars.label(trainer_profile && trainer_profile.display_name, sub.trainer.email)
      {bg, fg} = Avatars.color(label)

      %{
        sub: sub,
        trainer_label: label,
        trainer_profile_id: trainer_profile && trainer_profile.id,
        photo_url: trainer_profile && trainer_profile.photo_url,
        location_address: trainer_profile && trainer_profile.location_address,
        specialties: (trainer_profile && trainer_profile.specialties) || [],
        initials: Avatars.initials(trainer_profile && trainer_profile.display_name, sub.trainer.email),
        avatar_bg: bg,
        avatar_fg: fg
      }
    end)
    |> Enum.reject(&is_nil(&1.trainer_profile_id))
  end

  defp border_class("active"), do: "border-l-success"
  defp border_class("awaiting_payment"), do: "border-l-warning"
  defp border_class("declined"), do: "border-l-error"
  defp border_class(_), do: "border-l-base-300"

  defp badge_class("active"), do: "badge badge-success"
  defp badge_class("awaiting_payment"), do: "badge badge-warning"
  defp badge_class("declined"), do: "badge badge-error"
  defp badge_class(_), do: "badge badge-ghost"

  defp status_label("pending_quote"), do: "Awaiting Quote"
  defp status_label("awaiting_payment"), do: "Quoted — Review & Pay"
  defp status_label("declined"), do: "Declined"
  defp status_label("active"), do: "Active"
  defp status_label(other), do: String.capitalize(other)
end
