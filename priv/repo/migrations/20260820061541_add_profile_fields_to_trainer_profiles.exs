defmodule Zidolink.Repo.Migrations.AddProfileFieldsToTrainerProfiles do
  use Ecto.Migration

  def change do
    alter table(:trainer_profiles) do
      add :display_name, :string
      add :photo_url, :string
      add :profile_completed, :boolean, null: false, default: false
    end
  end
end
