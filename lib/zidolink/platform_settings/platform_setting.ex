defmodule Zidolink.PlatformSettings.PlatformSetting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "platform_settings" do
    field :signup_fee, :integer
    field :platform_markup_fee, :integer
    field :refund_deduction_fee, :integer

    timestamps(type: :utc_datetime)
  end

  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:signup_fee, :platform_markup_fee, :refund_deduction_fee])
    |> validate_required([:signup_fee, :platform_markup_fee, :refund_deduction_fee])
    |> validate_number(:signup_fee, greater_than: 0)
    |> validate_number(:platform_markup_fee, greater_than_or_equal_to: 0)
    |> validate_number(:refund_deduction_fee, greater_than_or_equal_to: 0)
  end
end
