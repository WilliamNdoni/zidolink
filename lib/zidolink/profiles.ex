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
end
