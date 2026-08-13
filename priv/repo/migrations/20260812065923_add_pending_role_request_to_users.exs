defmodule Zidolink.Repo.Migrations.AddPendingRoleRequestToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pending_role_request, :string
    end
  end
end
