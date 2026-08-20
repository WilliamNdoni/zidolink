defmodule Zidolink.Repo.Migrations.AddLocationAddressToTrainerProfiles do
  use Ecto.Migration

  def change do
    alter table(:trainer_profiles) do
      add :location_address, :string
    end
  end
end
