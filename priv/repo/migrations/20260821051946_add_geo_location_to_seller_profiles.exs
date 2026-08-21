defmodule Zidolink.Repo.Migrations.AddGeoLocationToSellerProfiles do
  use Ecto.Migration

  def change do
    alter table(:seller_profiles) do
      add :location, :geometry
    end

    execute "CREATE INDEX seller_profiles_location_index ON seller_profiles USING GIST (location)",
            "DROP INDEX seller_profiles_location_index"
  end
end
