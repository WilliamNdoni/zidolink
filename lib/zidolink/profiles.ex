defmodule Zidolink.Profiles do
  @moduledoc """
  The Profiles context — trainer, client, and seller profiles.
  """

  import Ecto.Query, warn: false
  alias Zidolink.Repo
  alias Zidolink.Profiles.{TrainerProfile, ClientProfile, SellerProfile}

  ## Trainer profiles

  def get_trainer_profile_by_user_id(user_id) do
    Repo.get_by(TrainerProfile, user_id: user_id)
  end

  def create_trainer_profile(attrs) do
    %TrainerProfile{}
    |> TrainerProfile.changeset(attrs)
    |> Repo.insert()
  end

  def update_trainer_profile(%TrainerProfile{} = profile, attrs) do
    profile
    |> TrainerProfile.changeset(attrs)
    |> Repo.update()
  end

  def get_or_build_trainer_profile(user_id) do
    get_trainer_profile_by_user_id(user_id) || %Zidolink.Profiles.TrainerProfile{user_id: user_id}
  end

  def list_completed_trainer_profiles do
    Repo.all(
      from p in Zidolink.Profiles.TrainerProfile,
        where: p.profile_completed == true,
        order_by: [desc: p.inserted_at]
    )
  end

  @trainers_per_page 12

  def search_trainer_profiles(query, page \\ 1)

  def search_trainer_profiles(query, page) when query in [nil, ""] do
    offset = (page - 1) * @trainers_per_page

    Repo.all(
      from p in Zidolink.Profiles.TrainerProfile,
        where: p.profile_completed == true,
        order_by: [desc: p.inserted_at],
        limit: ^@trainers_per_page,
        offset: ^offset
    )
  end

  def search_trainer_profiles(query, page) do
    pattern = "%#{query}%"
    offset = (page - 1) * @trainers_per_page

    Repo.all(
      from p in Zidolink.Profiles.TrainerProfile,
        where:
          p.profile_completed == true and
            (ilike(p.display_name, ^pattern) or
               ilike(p.bio, ^pattern) or
               fragment("EXISTS (SELECT 1 FROM unnest(?) AS s WHERE s ILIKE ?)", p.specialties, ^pattern)),
        order_by: [desc: p.inserted_at],
        limit: ^@trainers_per_page,
        offset: ^offset
    )
  end

  def nearby_trainer_profiles(lat, lng, radius_km, page \\ 1) do
    offset = (page - 1) * @trainers_per_page
    point = %Geo.Point{coordinates: {lng, lat}, srid: 4326}

    Repo.all(
      from p in Zidolink.Profiles.TrainerProfile,
        where: p.profile_completed == true and not is_nil(p.location),
        where:
          fragment(
            "ST_DWithin(?::geography, ?::geography, ?)",
            p.location,
            ^point,
            ^(radius_km * 1000)
          ),
        order_by: fragment("ST_Distance(?::geography, ?::geography)", p.location, ^point),
        limit: ^@trainers_per_page,
        offset: ^offset
    )
  end

  ## Client profiles

  def get_client_profile_by_user_id(user_id) do
    Repo.get_by(ClientProfile, user_id: user_id)
  end

  def create_client_profile(attrs) do
    %ClientProfile{}
    |> ClientProfile.changeset(attrs)
    |> Repo.insert()
  end

  def update_client_profile(%ClientProfile{} = profile, attrs) do
    profile
    |> ClientProfile.changeset(attrs)
    |> Repo.update()
  end

  ## Seller profiles

  def get_seller_profile_by_user_id(user_id) do
    Repo.get_by(SellerProfile, user_id: user_id)
  end

  def create_seller_profile(attrs) do
    %SellerProfile{}
    |> SellerProfile.changeset(attrs)
    |> Repo.insert()
  end

  def update_seller_profile(%SellerProfile{} = profile, attrs) do
    profile
    |> SellerProfile.changeset(attrs)
    |> Repo.update()
  end

  def get_or_build_seller_profile(user_id) do
    get_seller_profile_by_user_id(user_id) || %Zidolink.Profiles.SellerProfile{user_id: user_id}
  end

  def list_completed_seller_profiles do
    Repo.all(
      from p in Zidolink.Profiles.SellerProfile,
        where: p.profile_completed == true,
        order_by: [desc: p.inserted_at]
    )
  end

  @sellers_per_page 12

  def search_seller_profiles(query, page \\ 1)

  def search_seller_profiles(query, page) when query in [nil, ""] do
    offset = (page - 1) * @sellers_per_page

    Repo.all(
      from p in Zidolink.Profiles.SellerProfile,
        where: p.profile_completed == true,
        order_by: [desc: p.inserted_at],
        limit: ^@sellers_per_page,
        offset: ^offset
    )
  end

  def search_seller_profiles(query, page) do
    pattern = "%#{query}%"
    offset = (page - 1) * @sellers_per_page

    Repo.all(
      from p in Zidolink.Profiles.SellerProfile,
        where:
          p.profile_completed == true and
            (ilike(p.shop_name, ^pattern) or
               ilike(p.bio, ^pattern) or
               fragment("EXISTS (SELECT 1 FROM unnest(?) AS c WHERE c ILIKE ?)", p.categories, ^pattern)),
        order_by: [desc: p.inserted_at],
        limit: ^@sellers_per_page,
        offset: ^offset
    )
  end

  def nearby_seller_profiles(lat, lng, radius_km, page \\ 1) do
    offset = (page - 1) * @sellers_per_page
    point = %Geo.Point{coordinates: {lng, lat}, srid: 4326}

    Repo.all(
      from p in Zidolink.Profiles.SellerProfile,
        where: p.profile_completed == true and not is_nil(p.location),
        where:
          fragment(
            "ST_DWithin(?::geography, ?::geography, ?)",
            p.location,
            ^point,
            ^(radius_km * 1000)
          ),
        order_by: fragment("ST_Distance(?::geography, ?::geography)", p.location, ^point),
        limit: ^@sellers_per_page,
        offset: ^offset
    )
  end

end
