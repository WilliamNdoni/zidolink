defmodule Zidolink.Repo.Migrations.CreateSellerProfiles do
  use Ecto.Migration

  def change do
    create table(:seller_profiles) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :shop_name, :string
      add :bio, :text
      add :category, :string
      add :location_lat, :float
      add :location_lng, :float

      timestamps(type: :utc_datetime)
    end

    create unique_index(:seller_profiles, [:user_id])
    create index(:seller_profiles, [:category])
  end
end
