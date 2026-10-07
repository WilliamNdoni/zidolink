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
    case create_subscription(%{client_id: client_id, trainer_id: trainer_id, kind: kind, status: "pending_quote"}) do
      {:ok, subscription} ->
        broadcast_update(subscription)
        {:ok, subscription}

      error ->
        error
    end
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

    case update_subscription(subscription, %{
           price: price,
           status: "awaiting_payment",
           quote_history: history
         }) do
      {:ok, updated} ->
        broadcast_update(updated)
        {:ok, updated}

      error ->
        error
    end
  end

  def decline_quote(%Subscription{} = subscription, reason) do
    case update_subscription(subscription, %{status: "declined", decline_reason: reason}) do
      {:ok, updated} ->
        broadcast_update(updated)
        {:ok, updated}

      error ->
        error
    end
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

  def subscription_topic(client_id, trainer_id), do: "subscription:client:#{client_id}:trainer:#{trainer_id}"

  def trainer_subscriptions_topic(trainer_id), do: "trainer_subscriptions:#{trainer_id}"

  defp broadcast_update(subscription) do
    Phoenix.PubSub.broadcast(
      Zidolink.PubSub,
      subscription_topic(subscription.client_id, subscription.trainer_id),
      {:subscription_updated, subscription}
    )

    Phoenix.PubSub.broadcast(
      Zidolink.PubSub,
      trainer_subscriptions_topic(subscription.trainer_id),
      {:subscription_updated, subscription}
    )
  end

  def get_by_invoice_id(invoice_id) do
    Repo.get_by(Subscription, invoice_id: invoice_id)
  end

  def mark_payment_complete(%Subscription{kind: "one_time"} = subscription) do
    case update_subscription(subscription, %{status: "active"}) do
      {:ok, updated} -> broadcast_update(updated); {:ok, updated}
      error -> error
    end
  end

  def mark_payment_complete(%Subscription{} = subscription) do
    {days, _} = period_for_kind(subscription.kind)
    starts_at = DateTime.utc_now() |> DateTime.truncate(:second)
    ends_at = DateTime.add(starts_at, days, :day)

    case update_subscription(subscription, %{status: "active", starts_at: starts_at, ends_at: ends_at}) do
      {:ok, updated} -> broadcast_update(updated); {:ok, updated}
      error -> error
    end
  end

  def mark_payment_failed(%Subscription{kind: "one_time"} = subscription) do
    case update_subscription(subscription, %{status: "expired"}) do
      {:ok, updated} -> broadcast_update(updated); {:ok, updated}
      error -> error
    end
  end

  def mark_payment_failed(_), do: :ok

  defp period_for_kind("weekly"), do: {7, :day}
  defp period_for_kind("monthly"), do: {30, :day}
  defp period_for_kind(_), do: {30, :day}

end
