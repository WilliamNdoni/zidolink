defmodule ZidolinkWeb.ClientProgressLive.Index do
  use ZidolinkWeb, :live_view

  import ZidolinkWeb.WeightChart

  alias Zidolink.{WeightLogs, Profiles}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <div class="flex justify-between items-start">
          <.header>
            Progress
            <:subtitle>Track your weight over time</:subtitle>
          </.header>
          <.button :if={!@show_log_form} phx-click="show_log_form" class="btn btn-primary btn-sm">
            + Log Weight
          </.button>
        </div>

        <div :if={@show_log_form} class="border rounded-lg p-4 mt-4">
          <h3 class="font-semibold text-sm mb-2">Log Today's Weight</h3>

          <p :if={@already_logged_today} class="text-sm text-warning mb-2">
            You've already logged weight today. Submitting will update today's entry.
          </p>

          <form phx-submit="log_weight" class="space-y-2">
            <div>
              <label class="label text-xs">Weight</label>
              <div class="flex gap-2">
                <input
                  type="number"
                  step="0.1"
                  name="weight_value"
                  class="input input-bordered w-28"
                  placeholder={if @weight_unit == "kg", do: "e.g. 68.5", else: "e.g. 151"}
                  required
                  autofocus
                />
                <button
                  type="button"
                  phx-click="switch_weight_unit"
                  phx-value-unit="kg"
                  class={unit_class(@weight_unit, "kg")}
                >
                  kg
                </button>
                <button
                  type="button"
                  phx-click="switch_weight_unit"
                  phx-value-unit="lbs"
                  class={unit_class(@weight_unit, "lbs")}
                >
                  lbs
                </button>
              </div>
            </div>

            <div>
              <label class="label text-xs">Notes (optional)</label>
              <input type="text" name="note" class="input input-bordered w-full" placeholder="e.g. after workout" />
            </div>

            <div class="flex gap-2 pt-1">
              <.button class="btn btn-primary btn-sm">Save Weight</.button>
              <.button type="button" phx-click="hide_log_form" class="btn btn-outline btn-sm">Cancel</.button>
            </div>
          </form>
        </div>

        <div :if={@target_weight} class="rounded-lg p-4 mt-4 text-center border-2 border-[#0E7C5D] bg-[#0E7C5D]/10">
          <p class="text-sm font-medium text-[#0E7C5D]">&#127919; Target Weight</p>
          <p class="text-2xl font-bold text-[#0E7C5D]">{@target_weight} kg</p>
        </div>

        <div class="grid grid-cols-2 gap-3 mt-4">
          <div class="border rounded-lg p-3 text-center">
            <p class="text-xs text-base-content/60">Current</p>
            <p class="text-lg font-bold">{fmt(@stats.current)}</p>
          </div>
          <div class="border rounded-lg p-3 text-center">
            <p class="text-xs text-base-content/60">Change</p>
            <p class="text-lg font-bold">{fmt_signed(@stats.change)}</p>
          </div>
          <div class="border rounded-lg p-3 text-center">
            <p class="text-xs text-base-content/60">Lowest</p>
            <p class="text-lg font-bold">{fmt(@stats.lowest)}</p>
          </div>
          <div class="border rounded-lg p-3 text-center">
            <p class="text-xs text-base-content/60">Highest</p>
            <p class="text-lg font-bold">{fmt(@stats.highest)}</p>
          </div>
        </div>

        <div class="flex gap-2 flex-wrap mt-4">
          <button
            :for={{key, label} <- [{:month, "Month"}, {:three_months, "3 Months"}, {:year, "Year"}, {:all, "All Time"}]}
            phx-click="switch_period"
            phx-value-period={key}
            class={period_class(@period, key)}
          >
            {label}
          </button>
        </div>

        <div class="border rounded-lg p-4 mt-4">
          <.weight_chart points={@filtered_points} target_weight={@target_weight} />
        </div>

        <div :if={@recent_entries != []} class="mt-4">
          <h3 class="font-semibold text-sm mb-2">Recent Entries</h3>
          <div :for={entry <- @recent_entries} class="flex justify-between border-b border-base-200 py-2 text-sm">
            <span>{Calendar.strftime(entry.logged_on, "%d %b %Y")}</span>
            <span class="font-medium">{entry.weight_kg} kg</span>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile = Profiles.get_or_build_client_profile(user.id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Zidolink.PubSub, WeightLogs.topic(user.id))
    end

    socket =
      assign(socket,
        client_id: user.id,
        target_weight: profile.target_weight_kg,
        period: :three_months,
        show_log_form: false,
        weight_unit: "kg",
        all_logs: WeightLogs.list_logs_for_client(user.id)
      )
      |> recompute()

    {:ok, socket}
  end

  @impl true
  def handle_event("show_log_form", _params, socket), do: {:noreply, assign(socket, show_log_form: true)}
  def handle_event("hide_log_form", _params, socket), do: {:noreply, assign(socket, show_log_form: false)}

  def handle_event("switch_weight_unit", %{"unit" => unit}, socket) do
    {:noreply, assign(socket, weight_unit: unit)}
  end

  def handle_event("log_weight", %{"weight_value" => weight_value, "note" => note}, socket) do
    note = if note == "", do: nil, else: note
    parsed = parse_weight(weight_value)

    weight_kg =
      if socket.assigns.weight_unit == "lbs" do
        Float.round(parsed * 0.453592, 1)
      else
        Float.round(parsed, 1)
      end
    case WeightLogs.log_weight(socket.assigns.client_id, weight_kg, Date.utc_today(), note) do
      {:ok, _log} ->
        {:noreply,
         socket
         |> put_flash(:info, "Weight logged.")
         |> assign(show_log_form: false, all_logs: WeightLogs.list_logs_for_client(socket.assigns.client_id))
         |> recompute()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Couldn't log weight, please check the value.")}
    end
  end

  def handle_event("switch_period", %{"period" => period}, socket) do
    {:noreply, socket |> assign(period: String.to_existing_atom(period)) |> recompute()}
  end

  @impl true
  def handle_info({:weight_logged, _log}, socket) do
    {:noreply,
     socket
     |> assign(all_logs: WeightLogs.list_logs_for_client(socket.assigns.client_id))
     |> recompute()}
  end

  defp recompute(socket) do
    since =
      case socket.assigns.period do
        :month -> Date.add(Date.utc_today(), -30)
        :three_months -> Date.add(Date.utc_today(), -90)
        :year -> Date.add(Date.utc_today(), -365)
        :all -> nil
      end

    filtered_points =
      socket.assigns.all_logs
      |> Enum.filter(fn log -> is_nil(since) or Date.compare(log.logged_on, since) != :lt end)
      |> Enum.map(fn log -> %{date: log.logged_on, weight: log.weight_kg} end)

    sorted_desc = Enum.sort_by(socket.assigns.all_logs, & &1.logged_on, {:desc, Date})

    stats =
      case sorted_desc do
        [] ->
          %{current: nil, change: nil, lowest: nil, highest: nil}

        [latest | rest] ->
          previous = List.first(rest)
          change = if previous, do: latest.weight_kg - previous.weight_kg, else: 0.0
          weights = Enum.map(socket.assigns.all_logs, & &1.weight_kg)
          %{current: latest.weight_kg, change: change, lowest: Enum.min(weights), highest: Enum.max(weights)}
      end

    already_logged_today = Enum.any?(socket.assigns.all_logs, &(&1.logged_on == Date.utc_today()))

    assign(socket,
      filtered_points: filtered_points,
      stats: stats,
      recent_entries: Enum.take(sorted_desc, 5),
      already_logged_today: already_logged_today
    )
  end

  defp parse_weight(str) do
    case Float.parse(str) do
      {val, _} -> val
      :error -> 0.0
    end
  end

  defp unit_class(current, key) when current == key, do: "btn btn-primary btn-sm"
  defp unit_class(_current, _key), do: "btn btn-outline btn-sm"

  defp period_class(current, key) when current == key, do: "btn btn-primary btn-sm"
  defp period_class(_current, _key), do: "btn btn-outline btn-sm"

  defp fmt(nil), do: "N/A"
  defp fmt(val), do: "#{val} kg"

  defp fmt_signed(nil), do: "N/A"
  defp fmt_signed(val) when val >= 0, do: "+#{Float.round(val, 1)}"
  defp fmt_signed(val), do: "#{Float.round(val, 1)}"
end
