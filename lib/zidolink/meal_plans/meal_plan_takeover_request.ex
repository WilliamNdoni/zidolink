defmodule Zidolink.MealPlans.MealPlanTakeoverRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["pending", "approved", "declined"]

  schema "meal_plan_takeover_requests" do
    field :status, :string, default: "pending"
    field :requested_at, :utc_datetime

    belongs_to :meal_plan, Zidolink.MealPlans.MealPlan
    belongs_to :requesting_trainer, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(request, attrs) do
    request
    |> cast(attrs, [:meal_plan_id, :requesting_trainer_id, :status, :requested_at])
    |> validate_required([:meal_plan_id, :requesting_trainer_id, :status, :requested_at])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:meal_plan_id)
    |> foreign_key_constraint(:requesting_trainer_id)
  end
end
