defmodule Zidolink.MealPlans.MealItem do
  use Ecto.Schema
  import Ecto.Changeset

  @units ["g", "ml"]

  schema "meal_items" do
    field :food, :string
    field :quantity, :float
    field :unit, :string, default: "g"
    field :position, :integer, default: 0

    belongs_to :meal_slot, Zidolink.MealPlans.MealSlot

    timestamps(type: :utc_datetime)
  end

  def changeset(meal_item, attrs) do
    meal_item
    |> cast(attrs, [:meal_slot_id, :food, :quantity, :unit, :position])
    |> validate_required([:meal_slot_id, :food, :quantity, :unit])
    |> validate_inclusion(:unit, @units)
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:meal_slot_id)
  end
end
