defmodule Zidolink.WeightLogs.WeightLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weight_logs" do
    field :weight_kg, :float
    field :logged_on, :date
    field :note, :string

    belongs_to :client, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(weight_log, attrs) do
    weight_log
    |> cast(attrs, [:weight_kg, :logged_on, :note, :client_id])
    |> validate_required([:weight_kg, :logged_on, :client_id])
    |> validate_number(:weight_kg, greater_than: 0, less_than: 500)
    |> foreign_key_constraint(:client_id)
    |> unique_constraint([:client_id, :logged_on])
  end
end
