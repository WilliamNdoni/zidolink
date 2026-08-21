defmodule Zidolink.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  @kinds ["one_time", "weekly", "monthly"]
  @statuses [
    "pending_quote",
    "awaiting_payment",
    "declined",
    "active",
    "expired",
    "cancelled"
  ]

  schema "subscriptions" do
    field :kind, :string
    field :price, :integer
    field :status, :string, default: "pending_quote"
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :invoice_id, :string
    field :decline_reason, :string
    field :quote_history, {:array, :map}, default: []

    belongs_to :client, Zidolink.Accounts.User
    belongs_to :trainer, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :kind,
      :price,
      :status,
      :starts_at,
      :ends_at,
      :invoice_id,
      :decline_reason,
      :quote_history,
      :client_id,
      :trainer_id
    ])
    |> validate_required([:kind, :client_id, :trainer_id])
    |> validate_inclusion(:kind, @kinds)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:price, greater_than: 0)
    |> foreign_key_constraint(:client_id)
    |> foreign_key_constraint(:trainer_id)
  end
end
