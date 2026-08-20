defmodule Zidolink.Repo.Migrations.AddCategoriesToSellerProfiles do
  use Ecto.Migration

  def change do
    alter table(:seller_profiles) do
      add :categories, {:array, :string}, default: []
    end
  end
end
