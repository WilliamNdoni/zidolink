defmodule ZidolinkWeb.WeightChart do
  use Phoenix.Component

  attr :points, :list, required: true
  attr :target_weight, :float, default: nil

  def weight_chart(assigns) do
    assigns = assign_chart_data(assigns)

    ~H"""
    <div class="w-full">
      <svg viewBox="0 0 600 220" preserveAspectRatio="xMidYMid meet" class="w-full h-auto">
        <line
          :if={@target_y}
          x1="10"
          y1={@target_y}
          x2="590"
          y2={@target_y}
          stroke="#0E7C5D"
          stroke-width="3"
          stroke-dasharray="8,6"
        />
        <polyline points={@polyline} fill="none" stroke="#FF6F5E" stroke-width="3" />
        <circle :for={{x, y} <- @coords} cx={x} cy={y} r="4.5" fill="#FF6F5E" stroke="white" stroke-width="1.5" />
      </svg>

      <div :if={@points != []} class="flex justify-between text-xs sm:text-sm text-base-content/70 mt-1 px-1">
        <span>{@first_date}</span>
        <span>{@last_date}</span>
      </div>

      <div class="flex items-center gap-4 mt-2 text-xs sm:text-sm flex-wrap">
        <div class="flex items-center gap-1">
          <span class="inline-block w-4 h-0.5 bg-[#FF6F5E]"></span> Weight
        </div>
        <div :if={@target_weight_label} class="flex items-center gap-1">
          <span class="inline-block w-4 border-t-2 border-dashed border-[#0E7C5D]"></span>
          Target {@target_weight_label}
        </div>
      </div>

      <p :if={@points == []} class="text-center text-sm text-base-content/60 mt-2">
        No weight logged in this period yet.
      </p>
    </div>
    """
  end

  defp assign_chart_data(assigns) do
    points = assigns.points
    target = assigns.target_weight

    if points == [] do
      assign(assigns,
        polyline: "",
        coords: [],
        target_y: nil,
        first_date: nil,
        last_date: nil,
        target_weight_label: target && "#{target}kg"
      )
    else
      weights = Enum.map(points, & &1.weight)
      all_weights = if target, do: [target | weights], else: weights
      min_w = Enum.min(all_weights) - 1
      max_w = Enum.max(all_weights) + 1

      dates = Enum.map(points, & &1.date)
      min_d = Enum.min(dates, Date)
      max_d = Enum.max(dates, Date)
      span = max(Date.diff(max_d, min_d), 1)

      left = 10
      right = 590
      top = 15
      bottom = 205

      scale_x = fn date ->
        offset = Date.diff(date, min_d)
        left + offset / span * (right - left)
      end

      scale_y = fn weight ->
        ratio = (weight - min_w) / (max_w - min_w)
        bottom - ratio * (bottom - top)
      end

      coords = Enum.map(points, fn p -> {scale_x.(p.date), scale_y.(p.weight)} end)
      polyline = Enum.map_join(coords, " ", fn {x, y} -> "#{x},#{y}" end)
      target_y = target && scale_y.(target)

      assign(assigns,
        polyline: polyline,
        coords: coords,
        target_y: target_y,
        first_date: Calendar.strftime(min_d, "%d %b"),
        last_date: Calendar.strftime(max_d, "%d %b"),
        target_weight_label: target && "#{target}kg"
      )
    end
  end
end
