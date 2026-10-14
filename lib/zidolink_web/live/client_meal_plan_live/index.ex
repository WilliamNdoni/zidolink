defmodule ZidolinkWeb.ClientMealPlanLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.{MealPlans, Profiles, Accounts, Avatars}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header>Meal Plan</.header>

        <div :if={is_nil(@plan)} class="border rounded-lg p-4 mt-4 text-center text-sm text-base-content/60">
          Your trainer hasn't set up a meal plan for you yet.
        </div>

        <div :if={@plan}>
          <div :if={@active_request} class="modal modal-open">
            <div class="modal-box">
              <h3 class="font-semibold text-base">{@active_request_trainer_label} wants to manage your meal plan</h3>
              <p class="text-sm mt-2">
                If you approve, they will be able to view and edit your meal plan going forward.
              </p>
              <div class="modal-action">
                <.button phx-click="approve_takeover" class="btn btn-primary btn-sm">Allow</.button>
                <.button phx-click="decline_takeover" class="btn btn-outline btn-error btn-sm">Decline</.button>
              </div>
            </div>
          </div>

          <p class="text-sm text-base-content/60 mt-4">
            Managed by {@owner_label}
          </p>

          <div :if={@plan.trainer_note} class="border rounded-lg p-4 mt-3">
            <p class="text-sm text-base-content/80">{@plan.trainer_note}</p>
          </div>

          <div class="mt-4 space-y-3">
            <div :for={slot <- @visible_slots} class="border rounded-lg p-3">
              <p class="font-semibold text-sm">
                {slot.name}
                <span :if={slot.time} class="text-xs text-base-content/60 font-normal ml-1">
                  {Calendar.strftime(slot.time, "%I:%M %p")}
                </span>
              </p>
              <div class="mt-1 space-y-1">
                <p :for={item <- slot.meal_items} class="text-sm text-base-content/80">
                  {item.food}, {trim_qty(item.quantity)} {item.unit}
                </p>
              </div>
            </div>

            <p :if={@visible_slots == []} class="text-sm text-base-content/60 text-center">
              No meals set for today yet.
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    client = socket.assigns.current_scope.user
    plan = MealPlans.get_meal_plan_by_client_id(client.id)

    if connected?(socket), do: Phoenix.PubSub.subscribe(Zidolink.PubSub, MealPlans.topic(client.id))

    socket = assign(socket, client: client) |> load_plan(plan)
    {:ok, socket}
  end

  @impl true
  def handle_event("approve_takeover", _params, socket) do
    request = socket.assigns.active_request

    case MealPlans.approve_takeover(request) do
      {:ok, _updated} ->
        url = url(~p"/trainer/clients/#{socket.assigns.client.id}/meal-plan")

        Zidolink.Notifier.deliver_takeover_approved(
          request.requesting_trainer.email,
          socket.assigns.client.email,
          url
        )

        {:noreply,
         socket
         |> put_flash(:info, "#{socket.assigns.active_request_trainer_label} now manages your meal plan.")
         |> load_plan(MealPlans.get_meal_plan_by_client_id(socket.assigns.client.id))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Something went wrong, please try again.")}
    end
  end

  def handle_event("decline_takeover", _params, socket) do
    request = socket.assigns.active_request

    case MealPlans.decline_takeover(request) do
      {:ok, _updated} ->
        Zidolink.Notifier.deliver_takeover_declined(
          request.requesting_trainer.email,
          socket.assigns.client.email
        )

        {:noreply,
         socket
         |> put_flash(:info, "Request declined.")
         |> load_plan(MealPlans.get_meal_plan_by_client_id(socket.assigns.client.id))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Something went wrong, please try again.")}
    end
  end

  @impl true
  def handle_info(:meal_plan_changed, socket) do
    {:noreply, load_plan(socket, MealPlans.get_meal_plan_by_client_id(socket.assigns.client.id))}
  end

  def handle_info(:check_expiry, socket) do
    {:noreply, load_plan(socket, socket.assigns.plan)}
  end

  defp load_plan(socket, plan) do
    active_request = plan && MealPlans.get_active_takeover_request(plan.id)

    if active_request, do: schedule_expiry_check(socket, active_request)

    owner_label =
      if plan && plan.owner_trainer_id do
        owner_user = Accounts.get_user!(plan.owner_trainer_id)
        owner_profile = Profiles.get_trainer_profile_by_user_id(plan.owner_trainer_id)
        Avatars.label(owner_profile && owner_profile.display_name, owner_user.email)
      else
        "no one yet"
      end

    active_request_trainer_label =
      if active_request do
        requester_profile = Profiles.get_trainer_profile_by_user_id(active_request.requesting_trainer_id)
        Avatars.label(requester_profile && requester_profile.display_name, active_request.requesting_trainer.email)
      end

    visible_slots = if plan, do: Enum.filter(plan.meal_slots, & &1.active), else: []

    assign(socket,
      plan: plan,
      active_request: active_request,
      active_request_trainer_label: active_request_trainer_label,
      owner_label: owner_label,
      visible_slots: visible_slots
    )
  end

  defp schedule_expiry_check(socket, request) do
    if connected?(socket) do
      expires_at = MealPlans.takeover_expires_at(request)
      remaining_ms = DateTime.diff(expires_at, DateTime.utc_now(), :millisecond)
      if remaining_ms > 0, do: Process.send_after(self(), :check_expiry, remaining_ms)
    end
  end

  defp trim_qty(qty) when is_float(qty) do
    if qty == trunc(qty), do: trunc(qty), else: qty
  end

  defp trim_qty(qty), do: qty
end
