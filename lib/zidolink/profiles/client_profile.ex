defmodule Zidolink.Profiles.ClientProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "client_profiles" do
    field :location_lat, :float
    field :location_lng, :float

    belongs_to :user, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(client_profile, attrs) do
    client_profile
    |> cast(attrs, [:location_lat, :location_lng, :user_id])
    |> validate_required([:user_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end
end
