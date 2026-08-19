defmodule ZidolinkWeb.WebhookController do
  use ZidolinkWeb, :controller

  alias Zidolink.RoleApplications

  def intasend(conn, params) do
    expected_challenge = System.get_env("INTASEND_WEBHOOK_CHALLENGE")

    if params["challenge"] == expected_challenge do
      handle_event(params)
      json(conn, %{received: true})
    else
      conn
      |> put_status(401)
      |> json(%{error: "invalid challenge"})
    end
  end

  defp handle_event(%{"invoice_id" => invoice_id, "state" => state}) do
    case RoleApplications.get_by_invoice_id(invoice_id) do
      nil ->
        :ok

      application ->
        case state do
          "COMPLETE" -> RoleApplications.update_application(application, %{payment_status: "complete"})
          "FAILED" -> RoleApplications.update_application(application, %{payment_status: "failed"})
          _ -> :ok
        end
    end
  end

  defp handle_event(_params), do: :ok
end
