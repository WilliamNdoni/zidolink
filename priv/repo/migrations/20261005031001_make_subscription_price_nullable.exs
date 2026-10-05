defmodule Zidolink.Repo.Migrations.MakeSubscriptionPriceNullable do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      modify :price, :integer, null: true
    end
  end
end
