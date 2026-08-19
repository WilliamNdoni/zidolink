defmodule Zidolink.Withdrawals do
  @moduledoc """
  The Withdrawals context — a user's payout history and available balance.
  """

  import Ecto.Query, warn: false
  alias Zidolink.Repo
  alias Zidolink.Withdrawals.Withdrawal

  def create_withdrawal(attrs) do
    %Withdrawal{}
    |> Withdrawal.changeset(attrs)
    |> Repo.insert()
  end

  def update_withdrawal(%Withdrawal{} = withdrawal, attrs) do
    withdrawal
    |> Withdrawal.changeset(attrs)
    |> Repo.update()
  end

  def get_by_tracking_id(tracking_id) do
    Repo.get_by(Withdrawal, tracking_id: tracking_id)
  end

  def list_withdrawals_for_user(user_id) do
    Repo.all(
      from w in Withdrawal,
        where: w.user_id == ^user_id,
        order_by: [desc: w.inserted_at]
    )
  end

  def list_all_withdrawals do
    Repo.all(from w in Withdrawal, order_by: [desc: w.inserted_at])
    |> Repo.preload(:user)
  end

  @doc "Total ever withdrawn (completed only) for a given user."
  def total_withdrawn(user_id) do
    Repo.aggregate(
      from(w in Withdrawal, where: w.user_id == ^user_id and w.status == "completed"),
      :sum,
      :amount
    ) || 0
  end

  @doc "Money already sent out or completed — subtract this from earned revenue for available balance."
  def total_committed(user_id) do
    Repo.aggregate(
      from(w in Withdrawal,
        where: w.user_id == ^user_id and w.status in ["processing", "completed"]
      ),
      :sum,
      :amount
    ) || 0
  end

end
