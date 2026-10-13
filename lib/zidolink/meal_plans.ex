defmodule Zidolink.MealPlans do
  @moduledoc "Context for client meal plans, their day/meal/food structure, and trainer ownership handoff."

  import Ecto.Query, warn: false
  alias Zidolink.Repo
  alias Zidolink.MealPlans.{MealPlan, MealPlanTakeoverRequest, MealSlot, MealItem}

  @takeover_window_days 7

  ## Topics

  def topic(client_id), do: "meal_plan:#{client_id}"

  defp broadcast_change(client_id) do
    Phoenix.PubSub.broadcast(Zidolink.PubSub, topic(client_id), :meal_plan_changed)
  end

  ## Meal plans

  def get_meal_plan_by_client_id(client_id) do
    Repo.get_by(MealPlan, client_id: client_id)
    |> maybe_preload()
  end

  defp maybe_preload(nil), do: nil

  defp maybe_preload(plan) do
    Repo.preload(plan, meal_slots: {from(s in MealSlot, order_by: [asc: s.day_of_week, asc: s.position]), [:meal_items]})
  end

  @doc """
  Fetches a client's plan, or creates one owned by the given trainer if none exists yet.
  Only call this for a trainer who already has a confirmed active subscription with the client,
  that check belongs to the caller, this function trusts it.
  """
  def ensure_meal_plan(client_id, trainer_id) do
    case get_meal_plan_by_client_id(client_id) do
      nil ->
        {:ok, plan} =
          %MealPlan{}
          |> MealPlan.changeset(%{client_id: client_id, owner_trainer_id: trainer_id, structure: "same_daily"})
          |> Repo.insert()

        maybe_preload(plan)

      plan ->
        plan
    end
  end

  def update_meal_plan(%MealPlan{} = plan, attrs) do
    case plan |> MealPlan.changeset(attrs) |> Repo.update() do
      {:ok, updated} ->
        broadcast_change(updated.client_id)
        {:ok, maybe_preload(updated)}

      error ->
        error
    end
  end

  def is_owner?(%MealPlan{owner_trainer_id: owner_id}, trainer_id), do: owner_id == trainer_id

  ## Meal slots

  def add_meal_slot(meal_plan_id, attrs) do
    client_id = plan_client_id(meal_plan_id)

    result =
      %MealSlot{}
      |> MealSlot.changeset(Map.put(attrs, "meal_plan_id", meal_plan_id))
      |> Repo.insert()

    case result do
      {:ok, slot} -> broadcast_change(client_id); {:ok, slot}
      error -> error
    end
  end

  def update_meal_slot(%MealSlot{} = slot, attrs) do
    client_id = slot_client_id(slot)

    case slot |> MealSlot.changeset(attrs) |> Repo.update() do
      {:ok, updated} -> broadcast_change(client_id); {:ok, updated}
      error -> error
    end
  end

  def delete_meal_slot(%MealSlot{} = slot) do
    client_id = slot_client_id(slot)
    result = Repo.delete(slot)
    if match?({:ok, _}, result), do: broadcast_change(client_id)
    result
  end

  ## Meal items

  def add_meal_item(meal_slot_id, attrs) do
    client_id = slot_id_client_id(meal_slot_id)

    result =
      %MealItem{}
      |> MealItem.changeset(Map.put(attrs, "meal_slot_id", meal_slot_id))
      |> Repo.insert()

    case result do
      {:ok, item} -> broadcast_change(client_id); {:ok, item}
      error -> error
    end
  end

  def update_meal_item(%MealItem{} = item, attrs) do
    client_id = item_client_id(item)

    case item |> MealItem.changeset(attrs) |> Repo.update() do
      {:ok, updated} -> broadcast_change(client_id); {:ok, updated}
      error -> error
    end
  end

  def delete_meal_item(%MealItem{} = item) do
    client_id = item_client_id(item)
    result = Repo.delete(item)
    if match?({:ok, _}, result), do: broadcast_change(client_id)
    result
  end

  ## Takeover requests

  @doc "The current pending, unexpired request for a plan, or nil."
  def get_active_takeover_request(meal_plan_id) do
    cutoff = DateTime.add(DateTime.utc_now(), -@takeover_window_days, :day)

    Repo.one(
      from r in MealPlanTakeoverRequest,
        where: r.meal_plan_id == ^meal_plan_id and r.status == "pending" and r.requested_at >= ^cutoff,
        order_by: [desc: r.requested_at],
        limit: 1
    )
    |> Repo.preload(:requesting_trainer)
  end

  def takeover_expires_at(%MealPlanTakeoverRequest{requested_at: requested_at}) do
    DateTime.add(requested_at, @takeover_window_days, :day)
  end

  def request_takeover(meal_plan_id, requesting_trainer_id) do
    case get_active_takeover_request(meal_plan_id) do
      nil ->
        client_id = plan_client_id(meal_plan_id)

        result =
          %MealPlanTakeoverRequest{}
          |> MealPlanTakeoverRequest.changeset(%{
            meal_plan_id: meal_plan_id,
            requesting_trainer_id: requesting_trainer_id,
            status: "pending",
            requested_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })
          |> Repo.insert()

        case result do
          {:ok, request} -> broadcast_change(client_id); {:ok, request}
          error -> error
        end

      _existing ->
        {:error, :already_pending}
    end
  end

  def approve_takeover(%MealPlanTakeoverRequest{} = request) do
    plan = Repo.get!(MealPlan, request.meal_plan_id)

    Repo.transaction(fn ->
      {:ok, updated_request} =
        request |> MealPlanTakeoverRequest.changeset(%{status: "approved"}) |> Repo.update()

      {:ok, updated_plan} =
        plan |> MealPlan.changeset(%{owner_trainer_id: request.requesting_trainer_id}) |> Repo.update()

      {updated_request, updated_plan}
    end)
    |> case do
      {:ok, {updated_request, updated_plan}} ->
        broadcast_change(updated_plan.client_id)
        {:ok, updated_request}

      error ->
        error
    end
  end

  def decline_takeover(%MealPlanTakeoverRequest{} = request) do
    client_id = plan_client_id(request.meal_plan_id)

    case request |> MealPlanTakeoverRequest.changeset(%{status: "declined"}) |> Repo.update() do
      {:ok, updated} -> broadcast_change(client_id); {:ok, updated}
      error -> error
    end
  end

  ## Internal id lookups, used only to know which topic to broadcast on

  defp plan_client_id(meal_plan_id) do
    Repo.get!(MealPlan, meal_plan_id).client_id
  end

  defp slot_client_id(%MealSlot{meal_plan_id: meal_plan_id}), do: plan_client_id(meal_plan_id)

  defp slot_id_client_id(meal_slot_id) do
    Repo.get!(MealSlot, meal_slot_id) |> slot_client_id()
  end

  defp item_client_id(%MealItem{meal_slot_id: meal_slot_id}) do
    slot_id_client_id(meal_slot_id)
  end
end
