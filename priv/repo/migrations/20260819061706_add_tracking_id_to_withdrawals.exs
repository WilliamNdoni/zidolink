defmodule Zidolink.Repo.Migrations.AddTrackingIdToWithdrawals do
  use Ecto.Migration

  def change do
    alter table(:withdrawals) do
      add :tracking_id, :string
    end

    create index(:withdrawals, [:tracking_id])
  end
end
