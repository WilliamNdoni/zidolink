defmodule Zidolink.MealPlans.MealPlan do
  use Ecto.Schema
  import Ecto.Changeset

  @structures ["same_daily", "custom_per_day"]

  schema "meal_plans" do
    field :structure, :string, default: "same_daily"
    field :trainer_note, :string

    belongs_to :client, Zidolink.Accounts.User
    belongs_to :owner_trainer, Zidolink.Accounts.User

    has_many :meal_slots, Zidolink.MealPlans.MealSlot

    timestamps(type: :utc_datetime)
  end

  def changeset(meal_plan, attrs) do
    meal_plan
    |> cast(attrs, [:client_id, :owner_trainer_id, :structure, :trainer_note])
    |> validate_required([:client_id, :structure])
    |> validate_inclusion(:structure, @structures)
    |> foreign_key_constraint(:client_id)
    |> foreign_key_constraint(:owner_trainer_id)
    |> unique_constraint(:client_id)
  end
end
