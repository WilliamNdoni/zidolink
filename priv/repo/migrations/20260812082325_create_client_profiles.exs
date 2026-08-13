defmodule Zidolink.Repo.Migrations.CreateClientProfiles do
  use Ecto.Migration

  def change do
    create table(:client_profiles) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :location_lat, :float
      add :location_lng, :float

      timestamps(type: :utc_datetime)
    end

    create unique_index(:client_profiles, [:user_id])
  end
end
