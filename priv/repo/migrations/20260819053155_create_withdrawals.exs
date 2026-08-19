defmodule Zidolink.Repo.Migrations.CreateWithdrawals do
  use Ecto.Migration

  def change do
    create table(:withdrawals) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :amount, :integer, null: false
      add :status, :string, null: false, default: "processing"
      add :provider_reference, :string
      add :failure_reason, :text
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:withdrawals, [:user_id])
    create index(:withdrawals, [:status])
  end
end
