defmodule Zidolink.Withdrawals.Withdrawal do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["processing", "completed", "failed"]

  schema "withdrawals" do
    field :amount, :integer
    field :status, :string, default: "processing"
    field :provider_reference, :string
    field :failure_reason, :string
    field :completed_at, :utc_datetime
    field :tracking_id, :string

    belongs_to :user, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(withdrawal, attrs) do
    withdrawal
    |> cast(attrs, [
      :amount,
      :status,
      :provider_reference,
      :failure_reason,
      :completed_at,
      :tracking_id,
      :user_id
    ])
    |> validate_required([:amount, :user_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:amount, greater_than_or_equal_to: 10)
    |> foreign_key_constraint(:user_id)
  end
end
