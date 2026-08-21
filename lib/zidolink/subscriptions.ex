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

  def request_subscription(client_id, trainer_id, kind) do
    create_subscription(%{client_id: client_id, trainer_id: trainer_id, kind: kind, status: "pending_quote"})
  end

  def list_pending_quotes_for_trainer(trainer_id) do
    Repo.all(
      from s in Subscription,
        where: s.trainer_id == ^trainer_id and s.status == "pending_quote",
        order_by: [asc: s.inserted_at]
    )
    |> Repo.preload(:client)
  end

  def set_quote(%Subscription{} = subscription, price) do
    history = subscription.quote_history ++ [%{"price" => price, "set_at" => DateTime.utc_now() |> DateTime.to_iso8601()}]

    update_subscription(subscription, %{
      price: price,
      status: "awaiting_payment",
      quote_history: history
    })
  end

  def decline_quote(%Subscription{} = subscription, reason) do
    update_subscription(subscription, %{status: "declined", decline_reason: reason})
  end

  def book_one_time_session(client_id, trainer_id, price) do
    create_subscription(%{
      client_id: client_id,
      trainer_id: trainer_id,
      kind: "one_time",
      price: price,
      status: "awaiting_payment"
    })
  end

  def get_latest_one_time_booking(client_id, trainer_id) do
    Repo.one(
      from s in Subscription,
        where: s.client_id == ^client_id and s.trainer_id == ^trainer_id and s.kind == "one_time",
        order_by: [desc: s.inserted_at],
        limit: 1
    )
  end

  def get_latest_subscription_request(client_id, trainer_id) do
    Repo.one(
      from s in Subscription,
        where: s.client_id == ^client_id and s.trainer_id == ^trainer_id and s.kind in ["weekly", "monthly"],
        order_by: [desc: s.inserted_at],
        limit: 1
    )
  end

  def list_actionable_requests_for_trainer(trainer_id) do
    Repo.all(
      from s in Subscription,
        where:
          s.trainer_id == ^trainer_id and s.kind in ["weekly", "monthly"] and
            s.status in ["pending_quote", "declined"],
        order_by: [asc: s.inserted_at]
    )
    |> Repo.preload(:client)
  end
end
