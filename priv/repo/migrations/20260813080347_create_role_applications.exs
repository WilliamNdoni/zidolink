defmodule Zidolink.Repo.Migrations.CreateRoleApplications do
  use Ecto.Migration

  def change do
    create table(:role_applications) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role, :string, null: false
      add :status, :string, null: false, default: "pending_review"
      add :data, :map, null: false, default: %{}
      add :rejection_reason, :text
      add :reviewed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:role_applications, [:status])
    create index(:role_applications, [:user_id])
  end
end
