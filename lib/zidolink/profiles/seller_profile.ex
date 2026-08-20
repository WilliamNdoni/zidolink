defmodule Zidolink.Profiles.SellerProfile do
  use Ecto.Schema
  import Ecto.Changeset

  @categories ["nutrition", "equipment", "wear", "accessories", "recovery"]

  schema "seller_profiles" do
    field :shop_name, :string
    field :bio, :string
    field :category, :string
    field :categories, {:array, :string}, default: []
    field :location_lat, :float
    field :location_lng, :float
    field :photo_url, :string
    field :location_address, :string
    field :profile_completed, :boolean, default: false

    belongs_to :user, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(seller_profile, attrs) do
    seller_profile
    |> cast(attrs, [
      :shop_name,
      :bio,
      :categories,
      :location_lat,
      :location_lng,
      :photo_url,
      :location_address,
      :profile_completed,
      :user_id
    ])
    |> validate_required([:user_id, :shop_name])
    |> validate_length(:categories, min: 1, message: "select at least one category")
    |> validate_subset(:categories, @categories)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end
end
