defmodule ZidolinkWeb.TrainerClientLive.MealPlan do
  use ZidolinkWeb, :live_view

  alias Zidolink.{MealPlans, Subscriptions, Accounts, Profiles, Avatars}

  @days [
    {1, "Monday"},
    {2, "Tuesday"},
    {3, "Wednesday"},
    {4, "Thursday"},
    {5, "Friday"},
    {6, "Saturday"},
    {7, "Sunday"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div :if={@not_allowed} class="mx-auto max-w-lg text-center mt-8">
        <.header>Not available</.header>
        <p class="text-sm text-base-content/80 mt-2">
          This is only visible while you have an active subscription with this client.
        </p>
        <.link href={~p"/trainer/clients"} class="btn btn-primary btn-sm mt-4">Back to Clients</.link>
      </div>

      <div :if={!@not_allowed} class="mx-auto max-w-2xl">
        <.header>
          Meal Plan
          <:subtitle>{@client.email}</:subtitle>
        </.header>

        <div :if={is_nil(@plan)} class="border rounded-lg p-4 mt-4 text-center">
          <p class="text-sm text-base-content/80 mb-3">No meal plan set up yet for this client.</p>
          <div class="flex gap-2 justify-center flex-wrap">
            <.button phx-click="create_plan" phx-value-structure="same_daily" class="btn btn-primary btn-sm">
              Same meals every day
            </.button>
            <.button phx-click="create_plan" phx-value-structure="custom_per_day" class="btn btn-primary btn-sm">
              Different meals each day
            </.button>
          </div>
        </div>

        <div :if={@plan && !@is_owner} class="mt-4 space-y-3">
          <div class="border rounded-lg p-4">
            <p class="text-sm text-base-content/60">Managed by {@owner_label}</p>
          </div>

          <div class="border rounded-lg p-4">
            <%= cond do %>
              <% @active_request && @active_request.requesting_trainer_id == @trainer.id -> %>
                <p class="text-sm text-base-content/80">
                  Your request to take over this plan is awaiting the client's approval.
                </p>
              <% @active_request -> %>
                <p class="text-sm text-base-content/80">
                  A request to take over this plan is already pending.
                </p>
              <% true -> %>
                <.button phx-click="request_takeover" class="btn btn-primary btn-sm">
                  Take Over Editing
                </.button>
            <% end %>
          </div>

          <div :if={@plan.trainer_note} class="border rounded-lg p-4">
            <p class="text-sm text-base-content/80">{@plan.trainer_note}</p>
          </div>

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
        </div>

        <div :if={@plan && @is_owner}>
          <div class="border rounded-lg p-4 mt-4">
            <%= if @editing_note do %>
              <form phx-submit="save_note" class="flex flex-col gap-2">
                <textarea name="trainer_note" class="textarea textarea-bordered w-full" rows="2"><%= @plan.trainer_note %></textarea>
                <div class="flex gap-2">
                  <.button class="btn btn-primary btn-sm">Save</.button>
                  <.button type="button" phx-click="cancel_note" class="btn btn-outline btn-sm">Cancel</.button>
                </div>
              </form>
            <% else %>
              <div class="flex justify-between items-start gap-2">
                <p class="text-sm text-base-content/80">
                  {@plan.trainer_note || "No note set."}
                </p>
                <.button phx-click="edit_note" class="btn btn-primary btn-sm">Edit Note</.button>
              </div>
            <% end %>
          </div>

          <div class="border rounded-lg p-4 mt-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <p class="text-sm font-medium">Plan type</p>
              <p class="text-xs text-base-content/60">
                {if @plan.structure == "same_daily", do: "Same meals every day", else: "Different meals each day"}
              </p>
            </div>
            <.button phx-click="ask_switch_structure" class="btn btn-primary btn-sm">
              {if @plan.structure == "same_daily", do: "Switch to different meals each day", else: "Switch to same meals every day"}
            </.button>
          </div>

          <div :if={@confirm_switch} class="modal modal-open">
            <div class="modal-box">
              <%= if @confirm_switch == :to_custom do %>
                <h3 class="font-semibold text-base">Switch to Monday's Meal Plan?</h3>
                <p class="text-sm mt-2">
                  Your current meals will be kept and moved to Monday only. All other days will be cleared so you can plan them individually.
                </p>
              <% else %>
                <h3 class="font-semibold text-base">Switch to One Meal Plan for Every Day?</h3>
                <p class="text-sm mt-2">
                  Monday's meals will apply to every day. Meals for the other six days will be saved and restored if you switch back.
                </p>
              <% end %>
              <p class="text-sm mt-2">Nothing will be permanently deleted.</p>
              <p class="text-sm mt-2">Would you like to continue?</p>

              <div class="modal-action">
                <.button phx-click="confirm_switch_structure" class="btn btn-primary btn-sm">Continue</.button>
                <.button phx-click="cancel_switch_structure" class="btn btn-outline btn-sm">Cancel</.button>
              </div>
            </div>
            <label class="modal-backdrop" phx-click="cancel_switch_structure"></label>
          </div>

          <div :if={@plan.structure == "custom_per_day"} class="flex gap-2 flex-wrap mt-4">
            <button
              :for={{num, name} <- @days}
              phx-click="switch_day"
              phx-value-day={num}
              class={day_class(@selected_day, num)}
            >
              {name}
            </button>
          </div>

          <div class="mt-4 space-y-3">
            <div :for={slot <- @visible_slots} class="border rounded-lg p-3">
              <%= if @editing_slot_id == slot.id do %>
                <form phx-submit="save_slot" phx-value-id={slot.id} class="flex flex-wrap items-end gap-2">
                  <div>
                    <label class="label text-xs">Meal name</label>
                    <input type="text" name="name" value={slot.name} class="input input-bordered input-sm" required />
                  </div>
                  <div>
                    <label class="label text-xs">Time (optional)</label>
                    <input type="time" name="time" value={slot.time} class="input input-bordered input-sm" />
                  </div>
                  <.button class="btn btn-primary btn-sm">Save</.button>
                  <.button type="button" phx-click="cancel_edit_slot" class="btn btn-outline btn-sm">Cancel</.button>
                </form>
              <% else %>
                <div class="flex justify-between items-start">
                  <p class="font-semibold text-sm">
                    {slot.name}
                    <span :if={slot.time} class="text-xs text-base-content/60 font-normal ml-1">
                      {Calendar.strftime(slot.time, "%I:%M %p")}
                    </span>
                  </p>
                  <div class="flex gap-1">
                    <.button phx-click="edit_slot" phx-value-id={slot.id} class="btn btn-outline btn-xs">Edit</.button>
                    <.button phx-click="delete_slot" phx-value-id={slot.id} class="btn btn-outline btn-error btn-xs">
                      Delete
                    </.button>
                  </div>
                </div>

                <div class="mt-2 space-y-1">
                  <div :for={item <- slot.meal_items}>
                    <%= if @editing_item_id == item.id do %>
                      <form phx-submit="save_item_edit" phx-value-id={item.id} class="flex flex-wrap items-end gap-2 py-1">
                        <input type="text" name="food" value={item.food} class="input input-bordered input-sm" required />
                        <input type="number" step="0.1" name="quantity" value={trim_qty(item.quantity)} class="input input-bordered input-sm w-20" required />
                        <select name="unit" class="select select-bordered select-sm">
                          <option value="g" selected={item.unit == "g"}>g</option>
                          <option value="ml" selected={item.unit == "ml"}>ml</option>
                          <option value="nos" selected={item.unit == "nos"}>Nos</option>
                          <option value="tbsp" selected={item.unit == "tbsp"}>tbsp</option>
                          <option value="tsp" selected={item.unit == "tsp"}>tsp</option>
                        </select>
                        <.button class="btn btn-primary btn-xs">Save</.button>
                        <.button type="button" phx-click="cancel_edit_item" class="btn btn-outline btn-xs">Cancel</.button>
                      </form>
                    <% else %>
                      <div class="flex justify-between items-center text-sm border-b border-base-200 py-1">
                        <span>{item.food}, {trim_qty(item.quantity)} {item.unit}</span>
                        <div class="flex gap-2">
                          <button phx-click="edit_item" phx-value-id={item.id} class="text-primary text-xs">Edit</button>
                          <button phx-click="delete_item" phx-value-id={item.id} class="text-error text-xs">Remove</button>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>

                <%= if @adding_item_to == slot.id do %>
                  <form phx-submit="save_item" phx-value-slot_id={slot.id} class="flex flex-wrap items-end gap-2 mt-2">
                    <div>
                      <label class="label text-xs">Food</label>
                      <input type="text" name="food" class="input input-bordered input-sm" required autofocus />
                    </div>
                    <div>
                      <label class="label text-xs">Quantity</label>
                      <input type="number" step="0.1" name="quantity" class="input input-bordered input-sm w-20" required />
                    </div>
                    <div>
                      <label class="label text-xs">Unit</label>
                      <select name="unit" class="select select-bordered select-sm">
                        <option value="g">g</option>
                        <option value="ml">ml</option>
                        <option value="nos">Nos</option>
                        <option value="tbsp">tbsp</option>
                        <option value="tsp">tsp</option>
                      </select>
                    </div>
                    <.button class="btn btn-primary btn-sm">Add</.button>
                    <.button type="button" phx-click="cancel_add_item" class="btn btn-outline btn-sm">Cancel</.button>
                  </form>
                <% else %>
                  <.button phx-click="start_add_item" phx-value-slot_id={slot.id} class="btn btn-outline btn-xs mt-2">
                    + Add food
                  </.button>
                <% end %>
              <% end %>
            </div>

            <%= if @adding_slot do %>
              <form phx-submit="save_new_slot" class="border rounded-lg p-3 flex flex-wrap items-end gap-2">
                <div>
                  <label class="label text-xs">Meal name</label>
                  <input type="text" name="name" class="input input-bordered input-sm" placeholder="e.g. Breakfast" required autofocus />
                </div>
                <div>
                  <label class="label text-xs">Time (optional)</label>
                  <input type="time" name="time" class="input input-bordered input-sm" />
                </div>
                <.button class="btn btn-primary btn-sm">Add Meal</.button>
                <.button type="button" phx-click="cancel_add_slot" class="btn btn-outline btn-sm">Cancel</.button>
              </form>
            <% else %>
              <.button phx-click="start_add_slot" class="btn btn-primary btn-sm">+ Add Meal</.button>
            <% end %>
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
    active? = subscription && subscription.status == "active"

    if connected?(socket), do: Phoenix.PubSub.subscribe(Zidolink.PubSub, MealPlans.topic(client.id))

    socket =
      assign(socket,
        not_allowed: !active?,
        client: client,
        trainer: trainer,
        selected_day: 1,
        editing_note: false,
        editing_slot_id: nil,
        adding_slot: false,
        adding_item_to: nil,
        editing_item_id: nil,
        confirm_switch: nil,
        days: @days
      )
      |> load_plan()

    {:ok, socket}
  end

  @impl true
  def handle_event("create_plan", %{"structure" => structure}, socket) do
    {:ok, plan} = MealPlans.create_meal_plan_for_client(socket.assigns.client.id, socket.assigns.trainer.id, structure)
    {:noreply, socket |> assign(plan: plan, is_owner: true) |> recompute_visible_slots()}
  end

  def handle_event("request_takeover", _params, socket) do
    case MealPlans.request_takeover(socket.assigns.plan.id, socket.assigns.trainer.id) do
      {:ok, _request} ->
        trainer_profile = Profiles.get_trainer_profile_by_user_id(socket.assigns.trainer.id)
        trainer_label = Avatars.label(trainer_profile && trainer_profile.display_name, socket.assigns.trainer.email)
        url = url(~p"/client/meal-plan")

        Zidolink.Notifier.deliver_takeover_requested(socket.assigns.client.email, trainer_label, url)

        {:noreply,
         socket
         |> put_flash(:info, "Request sent, the client will need to approve it.")
         |> load_plan()}

      {:error, :already_pending} ->
        {:noreply, put_flash(socket, :error, "A request is already pending for this plan.")}
    end
  end

  def handle_event("switch_day", %{"day" => day}, socket) do
    {:noreply, socket |> assign(selected_day: String.to_integer(day)) |> recompute_visible_slots()}
  end

  def handle_event("edit_note", _params, socket), do: {:noreply, assign(socket, editing_note: true)}
  def handle_event("cancel_note", _params, socket), do: {:noreply, assign(socket, editing_note: false)}

  def handle_event("save_note", %{"trainer_note" => note}, socket) do
    {:ok, plan} = MealPlans.update_meal_plan(socket.assigns.plan, %{"trainer_note" => note})
    {:noreply, socket |> assign(plan: plan, editing_note: false) |> recompute_visible_slots()}
  end

  def handle_event("ask_switch_structure", _params, socket) do
    target = if socket.assigns.plan.structure == "same_daily", do: :to_custom, else: :to_same_daily
    {:noreply, assign(socket, confirm_switch: target)}
  end

  def handle_event("cancel_switch_structure", _params, socket) do
    {:noreply, assign(socket, confirm_switch: nil)}
  end

  def handle_event("confirm_switch_structure", _params, socket) do
    result =
      if socket.assigns.confirm_switch == :to_custom do
        MealPlans.switch_to_custom_per_day(socket.assigns.plan)
      else
        MealPlans.switch_to_same_daily(socket.assigns.plan)
      end

    case result do
      {:ok, plan} ->
        {:noreply, socket |> assign(plan: plan, confirm_switch: nil, selected_day: 1) |> recompute_visible_slots()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Couldn't switch plan type, please try again.")}
    end
  end

  def handle_event("start_add_slot", _params, socket), do: {:noreply, assign(socket, adding_slot: true)}
  def handle_event("cancel_add_slot", _params, socket), do: {:noreply, assign(socket, adding_slot: false)}

  def handle_event("save_new_slot", params, socket) do
    attrs = %{
      "name" => params["name"],
      "time" => blank_to_nil(params["time"]),
      "day_of_week" => if(socket.assigns.plan.structure == "custom_per_day", do: socket.assigns.selected_day, else: nil),
      "position" => length(socket.assigns.plan.meal_slots)
    }

    {:ok, _slot} = MealPlans.add_meal_slot(socket.assigns.plan.id, attrs)
    {:noreply, socket |> assign(adding_slot: false) |> load_plan()}
  end

  def handle_event("edit_slot", %{"id" => id}, socket) do
    {:noreply, assign(socket, editing_slot_id: String.to_integer(id))}
  end

  def handle_event("cancel_edit_slot", _params, socket), do: {:noreply, assign(socket, editing_slot_id: nil)}

  def handle_event("save_slot", %{"id" => id} = params, socket) do
    slot = find_slot(socket, String.to_integer(id))
    attrs = %{"name" => params["name"], "time" => blank_to_nil(params["time"])}
    {:ok, _updated} = MealPlans.update_meal_slot(slot, attrs)
    {:noreply, socket |> assign(editing_slot_id: nil) |> load_plan()}
  end

  def handle_event("delete_slot", %{"id" => id}, socket) do
    slot = find_slot(socket, String.to_integer(id))
    {:ok, _} = MealPlans.delete_meal_slot(slot)
    {:noreply, load_plan(socket)}
  end

  def handle_event("start_add_item", %{"slot_id" => slot_id}, socket) do
    {:noreply, assign(socket, adding_item_to: String.to_integer(slot_id))}
  end

  def handle_event("cancel_add_item", _params, socket), do: {:noreply, assign(socket, adding_item_to: nil)}

  def handle_event("save_item", %{"slot_id" => slot_id} = params, socket) do
    case Float.parse(params["quantity"] || "") do
      {qty, _} ->
        attrs = %{"food" => params["food"], "quantity" => qty, "unit" => params["unit"]}
        {:ok, _item} = MealPlans.add_meal_item(String.to_integer(slot_id), attrs)
        {:noreply, socket |> assign(adding_item_to: nil) |> load_plan()}

      :error ->
        {:noreply, put_flash(socket, :error, "Please enter a valid quantity.")}
    end
  end

  def handle_event("delete_item", %{"id" => id}, socket) do
    item = find_item(socket, String.to_integer(id))
    {:ok, _} = MealPlans.delete_meal_item(item)
    {:noreply, load_plan(socket)}
  end

  def handle_event("edit_item", %{"id" => id}, socket) do
    {:noreply, assign(socket, editing_item_id: String.to_integer(id))}
  end

  def handle_event("cancel_edit_item", _params, socket) do
    {:noreply, assign(socket, editing_item_id: nil)}
  end

  def handle_event("save_item_edit", %{"id" => id} = params, socket) do
    item = find_item(socket, String.to_integer(id))

    case Float.parse(params["quantity"] || "") do
      {qty, _} ->
        attrs = %{"food" => params["food"], "quantity" => qty, "unit" => params["unit"]}
        {:ok, _updated} = MealPlans.update_meal_item(item, attrs)
        {:noreply, socket |> assign(editing_item_id: nil) |> load_plan()}

      :error ->
        {:noreply, put_flash(socket, :error, "Please enter a valid quantity.")}
    end
  end

  @impl true
  def handle_info(:meal_plan_changed, socket) do
    {:noreply, load_plan(socket)}
  end

  defp load_plan(socket) do
    plan = MealPlans.get_meal_plan_by_client_id(socket.assigns.client.id)
    is_owner = plan && MealPlans.is_owner?(plan, socket.assigns.trainer.id)
    active_request = plan && MealPlans.get_active_takeover_request(plan.id)

    owner_label =
      if plan && plan.owner_trainer_id do
        owner_user = Accounts.get_user!(plan.owner_trainer_id)
        owner_profile = Profiles.get_trainer_profile_by_user_id(plan.owner_trainer_id)
        Avatars.label(owner_profile && owner_profile.display_name, owner_user.email)
      end

    socket
    |> assign(plan: plan, is_owner: is_owner, active_request: active_request, owner_label: owner_label)
    |> recompute_visible_slots()
  end

  defp recompute_visible_slots(socket) do
    plan = socket.assigns.plan

    visible =
      cond do
        is_nil(plan) -> []
        plan.structure == "same_daily" -> Enum.filter(plan.meal_slots, & &1.active)
        true -> Enum.filter(plan.meal_slots, &(&1.active && &1.day_of_week == socket.assigns.selected_day))
      end

    assign(socket, visible_slots: visible)
  end

  defp find_slot(socket, id), do: Enum.find(socket.assigns.plan.meal_slots, &(&1.id == id))

  defp find_item(socket, id) do
    socket.assigns.plan.meal_slots
    |> Enum.flat_map(& &1.meal_items)
    |> Enum.find(&(&1.id == id))
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(val), do: val

  defp trim_qty(qty) when is_float(qty) do
    if qty == trunc(qty), do: trunc(qty), else: qty
  end

  defp trim_qty(qty), do: qty

  defp day_class(current, key) when current == key, do: "btn btn-primary btn-sm"
  defp day_class(_current, _key), do: "btn btn-outline btn-sm"
end
