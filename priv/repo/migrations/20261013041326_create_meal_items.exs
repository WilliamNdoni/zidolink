defmodule Zidolink.Repo.Migrations.CreateMealItems do
  use Ecto.Migration

  def change do
    create table(:meal_items) do
      add :meal_slot_id, references(:meal_slots, on_delete: :delete_all), null: false
      add :food, :string, null: false
      add :quantity, :float, null: false
      add :unit, :string, null: false, default: "g"
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:meal_items, [:meal_slot_id])
  end
end
