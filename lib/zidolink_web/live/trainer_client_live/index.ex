defmodule ZidolinkWeb.TrainerClientLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.{Subscriptions, Profiles, Avatars}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header>Clients</.header>

        <div class="flex gap-2 mt-4 flex-wrap">
          <button
            :for={{key, label} <- [{:active, "Active"}, {:overdue, "Overdue"}, {:inactive, "Inactive"}]}
            phx-click="switch_tab"
            phx-value-tab={key}
            class={tab_class(@tab, key)}
          >
            {label} ({@counts[key]})
          </button>
        </div>

        <input
          type="text"
          phx-change="search"
          name="q"
          value={@query}
          placeholder="Search by name or email..."
          class="input input-bordered w-full mt-4"
        />

        <div :if={@filtered == []} class="mt-6 text-center text-base-content/80">
          No clients here yet.
        </div>

        <div
          :for={item <- @filtered}
          class={"mt-4 border rounded-lg p-4 border-l-4 #{border_class(item.category)}"}
        >
          <div class="flex gap-3 items-start">
            <div
              class="flex-none size-12 rounded-full flex items-center justify-center font-bold text-sm"
              style={"background-color: #{item.avatar_bg}; color: #{item.avatar_fg}"}
            >
              {item.initials}
            </div>

            <div class="flex-1 min-w-0">
              <div class="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-2">
                <div>
                  <p class="font-semibold">{item.label}</p>
                  <p class="text-sm text-base-content/60 truncate">{item.sub.client.email}</p>
                  <p :if={item.phone} class="text-sm text-base-content/60">{item.phone}</p>
                </div>
                <span class={badge_class(item.category)}>{category_label(item.category)}</span>
              </div>

              <div class="mt-2 text-sm text-base-content/80">
                <p>{String.capitalize(item.sub.kind)} plan &middot; Last paid KES {item.sub.price}</p>
                <p :if={item.sub.ends_at}>Due {Calendar.strftime(item.sub.ends_at, "%d %b %Y")}</p>
              </div>

              <div class="flex gap-2 mt-3">
                <.link href={~p"/trainer/clients/#{item.sub.client_id}"} class="btn btn-primary btn-sm">
                  View Details
                </.link>
                <.button class="btn btn-outline btn-error btn-sm">Deactivate</.button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    clients = build_client_items(user.id)
    {:ok, assign(socket, all_clients: clients, tab: :active, query: "") |> recompute()}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, socket |> assign(tab: String.to_existing_atom(tab)) |> recompute()}
  end

  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, socket |> assign(query: query) |> recompute()}
  end

  defp build_client_items(trainer_id) do
    Subscriptions.list_clients_for_trainer(trainer_id)
    |> Enum.map(fn {sub, category} ->
      profile = Profiles.get_client_profile_by_user_id(sub.client_id)
      label = Avatars.label(profile && profile.display_name, sub.client.email)
      {bg, fg} = Avatars.color(label)

      %{
        sub: sub,
        category: category,
        label: label,
        initials: Avatars.initials(profile && profile.display_name, sub.client.email),
        avatar_bg: bg,
        avatar_fg: fg,
        phone: (profile && profile.phone_visible_to_trainers && sub.client.phone) || nil
      }
    end)
  end

  defp recompute(socket) do
    all = socket.assigns.all_clients
    tab = socket.assigns.tab
    query = String.downcase(socket.assigns.query || "")

    counts = %{
      active: Enum.count(all, &(&1.category == :active)),
      overdue: Enum.count(all, &(&1.category == :overdue)),
      inactive: Enum.count(all, &(&1.category == :inactive))
    }

    filtered =
      all
      |> Enum.filter(&(&1.category == tab))
      |> Enum.filter(fn item ->
        query == "" or String.contains?(String.downcase(item.label), query) or
          String.contains?(String.downcase(item.sub.client.email), query)
      end)

    assign(socket, counts: counts, filtered: filtered)
  end

  defp tab_class(current, key) when current == key, do: "btn btn-primary btn-sm"
  defp tab_class(_current, _key), do: "btn btn-outline btn-sm"

  defp badge_class(:active), do: "badge badge-success"
  defp badge_class(:overdue), do: "badge badge-error"
  defp badge_class(:inactive), do: "badge badge-ghost"

  defp border_class(:active), do: "border-l-success"
  defp border_class(:overdue), do: "border-l-error"
  defp border_class(:inactive), do: "border-l-base-300"

  defp category_label(:active), do: "Active"
  defp category_label(:overdue), do: "Overdue"
  defp category_label(:inactive), do: "Inactive"
end
