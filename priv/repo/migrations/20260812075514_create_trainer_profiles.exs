defmodule Zidolink.Repo.Migrations.CreateTrainerProfiles do
  use Ecto.Migration

  def change do
    create table(:trainer_profiles) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :bio, :text
      add :specialties, {:array, :string}, default: []
      add :location_lat, :float
      add :location_lng, :float
      add :accepting_new_clients, :boolean, default: true, null: false
      add :rating_avg, :float, default: 0.0
      add :rating_count, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:trainer_profiles, [:user_id])
  end
end
