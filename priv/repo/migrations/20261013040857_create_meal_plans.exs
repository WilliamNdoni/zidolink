defmodule Zidolink.Repo.Migrations.CreateMealPlans do
  use Ecto.Migration

  def change do
    create table(:meal_plans) do
      add :client_id, references(:users, on_delete: :delete_all), null: false
      add :owner_trainer_id, references(:users, on_delete: :nilify_all)
      add :structure, :string, null: false, default: "same_daily"
      add :trainer_note, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:meal_plans, [:client_id])
    create index(:meal_plans, [:owner_trainer_id])
  end
end
