defmodule Zidolink.Subscriptions do
  @moduledoc """
  The Subscriptions context — links clients to trainers, tracks access.
  """

  import Ecto.Query, warn: false
  alias Zidolink.Repo
  alias Zidolink.Subscriptions.Subscription

  def create_subscription(attrs) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Checks whether a client currently has active access to a given trainer —
  this is the core access-control check used throughout the app.
  """
  def active_subscription?(client_id, trainer_id) do
    Repo.exists?(
      from s in Subscription,
        where:
          s.client_id == ^client_id and s.trainer_id == ^trainer_id and
            s.status == "active"
    )
  end

  def list_subscriptions_for_client(client_id) do
    Repo.all(from s in Subscription, where: s.client_id == ^client_id)
  end

  def list_subscriptions_for_trainer(trainer_id) do
    Repo.all(from s in Subscription, where: s.trainer_id == ^trainer_id)
  end
end
