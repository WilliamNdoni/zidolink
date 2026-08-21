defmodule Zidolink.Repo.Migrations.AddSessionPriceToTrainerProfiles do
  use Ecto.Migration

  def change do
    alter table(:trainer_profiles) do
      add :session_price, :integer
    end
  end
end
