defmodule Zidolink.Repo.Migrations.AddAmountPaidToRoleApplications do
  use Ecto.Migration

  def change do
    alter table(:role_applications) do
      add :amount_paid, :integer
    end
  end
end
