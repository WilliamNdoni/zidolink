defmodule Zidolink.Repo.Migrations.CreateMealSlots do
  use Ecto.Migration

  def change do
    create table(:meal_slots) do
      add :meal_plan_id, references(:meal_plans, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :time, :time
      add :day_of_week, :integer
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:meal_slots, [:meal_plan_id])
  end
end
