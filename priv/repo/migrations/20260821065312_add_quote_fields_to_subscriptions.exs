defmodule Zidolink.Repo.Migrations.AddQuoteFieldsToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :invoice_id, :string
      add :decline_reason, :string
      add :quote_history, {:array, :map}, default: []
    end

    create index(:subscriptions, [:invoice_id])
  end
end
