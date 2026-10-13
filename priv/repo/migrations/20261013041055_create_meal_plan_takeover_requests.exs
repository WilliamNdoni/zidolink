defmodule Zidolink.Repo.Migrations.CreateMealPlanTakeoverRequests do
  use Ecto.Migration

  def change do
    create table(:meal_plan_takeover_requests) do
      add :meal_plan_id, references(:meal_plans, on_delete: :delete_all), null: false
      add :requesting_trainer_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"
      add :requested_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:meal_plan_takeover_requests, [:meal_plan_id])
    create index(:meal_plan_takeover_requests, [:requesting_trainer_id])
  end
end
