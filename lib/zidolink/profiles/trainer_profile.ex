defmodule Zidolink.Profiles.TrainerProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trainer_profiles" do
    field :bio, :string
    field :specialties, {:array, :string}, default: []
    field :location_lat, :float
    field :location_lng, :float
    field :location, Geo.PostGIS.Geometry
    field :accepting_new_clients, :boolean, default: true
    field :rating_avg, :float, default: 0.0
    field :rating_count, :integer, default: 0
    field :display_name, :string
    field :photo_url, :string
    field :profile_completed, :boolean, default: false
    field :location_address, :string

    belongs_to :user, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(trainer_profile, attrs) do
    trainer_profile
    |> cast(attrs, [
      :bio,
      :specialties,
      :location_lat,
      :location_lng,
      :accepting_new_clients,
      :display_name,
      :photo_url,
      :profile_completed,
      :location_address,
      :user_id
    ])
    |> validate_required([:user_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
    |> put_geo_point()
  end

  defp put_geo_point(changeset) do
    lat = get_field(changeset, :location_lat)
    lng = get_field(changeset, :location_lng)

    if lat && lng do
      put_change(changeset, :location, %Geo.Point{coordinates: {lng, lat}, srid: 4326})
    else
      changeset
    end
  end
end
