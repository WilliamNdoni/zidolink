defmodule Zidolink.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :client_id, references(:users, on_delete: :delete_all), null: false
      add :trainer_id, references(:users, on_delete: :delete_all), null: false
      add :kind, :string, null: false
      add :price, :integer, null: false
      add :status, :string, null: false, default: "pending"
      add :starts_at, :utc_datetime
      add :ends_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:subscriptions, [:client_id, :trainer_id, :status])
    create index(:subscriptions, [:trainer_id])
  end
end
