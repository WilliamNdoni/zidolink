defmodule Zidolink.Repo.Migrations.CreatePlatformSettings do
  use Ecto.Migration

  def change do
    create table(:platform_settings) do
      add :signup_fee, :integer, null: false, default: 5000
      add :platform_markup_fee, :integer, null: false, default: 100
      add :refund_deduction_fee, :integer, null: false, default: 500

      timestamps(type: :utc_datetime)
    end
  end
end
