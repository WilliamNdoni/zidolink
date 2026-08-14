defmodule Zidolink.Repo.Migrations.AddPaymentFieldsToRoleApplications do
  use Ecto.Migration

  def change do
    alter table(:role_applications) do
      add :invoice_id, :string
      add :payment_status, :string, null: false, default: "awaiting_payment"
    end

    create index(:role_applications, [:invoice_id])
  end
end
