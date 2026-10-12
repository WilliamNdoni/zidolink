defmodule Zidolink.WeightLogs do
  @moduledoc "Context for client weight tracking."

  import Ecto.Query, warn: false
  alias Zidolink.Repo
  alias Zidolink.WeightLogs.WeightLog

  def topic(client_id), do: "weight_logs:#{client_id}"

  def log_weight(client_id, weight_kg, logged_on, note \\ nil) do
    attrs = %{client_id: client_id, weight_kg: weight_kg, logged_on: logged_on, note: note}

    result =
      %WeightLog{}
      |> WeightLog.changeset(attrs)
      |> Repo.insert(
        on_conflict: {:replace, [:weight_kg, :note, :updated_at]},
        conflict_target: [:client_id, :logged_on]
      )

    case result do
      {:ok, log} ->
        Phoenix.PubSub.broadcast(Zidolink.PubSub, topic(client_id), {:weight_logged, log})
        {:ok, log}

      error ->
        error
    end
  end

  def list_logs_for_client(client_id, since \\ nil) do
    query =
      from w in WeightLog,
        where: w.client_id == ^client_id,
        order_by: [asc: w.logged_on]

    query = if since, do: from(w in query, where: w.logged_on >= ^since), else: query

    Repo.all(query)
  end
end
