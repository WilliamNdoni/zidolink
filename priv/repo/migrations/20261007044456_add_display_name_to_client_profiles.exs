defmodule Zidolink.Repo.Migrations.AddDisplayNameToClientProfiles do
  use Ecto.Migration

  def change do
    alter table(:client_profiles) do
      add :display_name, :string
      add :phone_visible_to_trainers, :boolean, null: false, default: true
    end
  end
end
