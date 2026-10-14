defmodule Zidolink.Repo.Migrations.AddActiveToMealSlots do
  use Ecto.Migration

  def change do
    alter table(:meal_slots) do
      add :active, :boolean, null: false, default: true
    end
  end
end
