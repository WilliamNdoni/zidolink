defmodule Zidolink.Repo.Migrations.CreateWeightLogs do
  use Ecto.Migration

  def change do
    create table(:weight_logs) do
      add :client_id, references(:users, on_delete: :delete_all), null: false
      add :weight_kg, :float, null: false
      add :logged_on, :date, null: false
      add :note, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:weight_logs, [:client_id, :logged_on])
    create index(:weight_logs, [:client_id])
  end
end
