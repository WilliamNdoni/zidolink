defmodule Zidolink.MealPlans.MealSlot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meal_slots" do
    field :name, :string
    field :time, :time
    field :day_of_week, :integer
    field :position, :integer, default: 0
    field :active, :boolean, default: true

    belongs_to :meal_plan, Zidolink.MealPlans.MealPlan
    has_many :meal_items, Zidolink.MealPlans.MealItem

    timestamps(type: :utc_datetime)
  end

  def changeset(meal_slot, attrs) do
    meal_slot
    |> cast(attrs, [:meal_plan_id, :name, :time, :day_of_week, :position, :active])
    |> validate_required([:meal_plan_id, :name])
    |> validate_inclusion(:day_of_week, 1..7)
    |> foreign_key_constraint(:meal_plan_id)
  end
end
