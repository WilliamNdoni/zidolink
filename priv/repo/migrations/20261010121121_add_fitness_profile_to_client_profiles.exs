defmodule Zidolink.Repo.Migrations.AddFitnessProfileToClientProfiles do
  use Ecto.Migration

  def change do
    alter table(:client_profiles) do
      add :height_cm, :float
      add :age, :integer
      add :gender, :string
      add :activity_level, :string
      add :goal_text, :text
      add :target_weight_kg, :float
    end
  end
end
