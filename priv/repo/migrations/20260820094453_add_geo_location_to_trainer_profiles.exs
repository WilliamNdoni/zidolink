defmodule Zidolink.Repo.Migrations.AddGeoLocationToTrainerProfiles do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS postgis", "DROP EXTENSION IF EXISTS postgis"

    alter table(:trainer_profiles) do
      add :location, :geometry
    end

    execute "CREATE INDEX trainer_profiles_location_index ON trainer_profiles USING GIST (location)",
            "DROP INDEX trainer_profiles_location_index"
  end
end
