defmodule Zidolink.RoleApplications.RoleApplication do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ["trainer", "seller"]
  @statuses ["pending_review", "approved", "rejected"]
  @payment_statuses ["awaiting_payment", "complete", "failed", "expired"]

  schema "role_applications" do
    field :role, :string
    field :status, :string, default: "pending_review"
    field :data, :map, default: %{}
    field :rejection_reason, :string
    field :reviewed_at, :utc_datetime
    field :invoice_id, :string
    field :payment_status, :string, default: "awaiting_payment"
    field :amount_paid, :integer

    belongs_to :user, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(role_application, attrs) do
    role_application
    |> cast(attrs, [
      :role,
      :status,
      :data,
      :rejection_reason,
      :reviewed_at,
      :invoice_id,
      :payment_status,
      :amount_paid,
      :user_id
    ])
    |> validate_required([:role, :user_id])
    |> validate_inclusion(:role, @roles)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:payment_status, @payment_statuses)
    |> foreign_key_constraint(:user_id)
  end
end
