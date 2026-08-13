defmodule Zidolink.Profiles.SellerProfile do
  use Ecto.Schema
  import Ecto.Changeset

  @categories ["nutrition", "equipment", "wear"]

  schema "seller_profiles" do
    field :shop_name, :string
    field :bio, :string
    field :category, :string
    field :location_lat, :float
    field :location_lng, :float

    belongs_to :user, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(seller_profile, attrs) do
    seller_profile
    |> cast(attrs, [:shop_name, :bio, :category, :location_lat, :location_lng, :user_id])
    |> validate_required([:user_id, :shop_name, :category])
    |> validate_inclusion(:category, @categories)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end
end
