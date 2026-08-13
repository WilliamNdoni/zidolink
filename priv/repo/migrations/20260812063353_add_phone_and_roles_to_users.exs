defmodule Zidolink.Repo.Migrations.AddPhoneAndRolesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :phone, :string
      add :roles, {:array, :string}, default: [], null: false
    end

    create unique_index(:users, [:phone])
  end
end
