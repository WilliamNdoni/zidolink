defmodule Zidolink.Repo.Migrations.AddProfileFieldsToSellerProfiles do
  use Ecto.Migration

  def change do
    alter table(:seller_profiles) do
      add :photo_url, :string
      add :location_address, :string
      add :profile_completed, :boolean, null: false, default: false
    end
  end
end
