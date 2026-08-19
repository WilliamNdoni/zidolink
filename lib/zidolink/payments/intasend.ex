defmodule Zidolink.Payments.Intasend do
  @moduledoc "Thin client for IntaSend's collection (M-Pesa STK Push) API."

  @base_url "https://sandbox.intasend.com/api/v1"

  def stk_push(phone_number, amount, api_ref) do
    secret_key = System.get_env("INTASEND_SECRET_KEY")

    case Req.post("#{@base_url}/payment/mpesa-stk-push/",
           headers: [{"authorization", "Bearer #{secret_key}"}],
           json: %{
             "phone_number" => phone_number,
             "amount" => to_string(amount),
             "api_ref" => api_ref
           }
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def check_status(invoice_id) do
    secret_key = System.get_env("INTASEND_SECRET_KEY")

    case Req.post("#{@base_url}/payment/status/",
           headers: [{"authorization", "Bearer #{secret_key}"}],
           json: %{"invoice_id" => invoice_id}
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

    def send_money(phone_number, amount, name) do
    secret_key = System.get_env("INTASEND_SECRET_KEY")

    case Req.post("#{@base_url}/send-money/initiate/",
           headers: [{"authorization", "Bearer #{secret_key}"}],
           json: %{
             "provider" => "MPESA-B2C",
             "currency" => "KES",
             "requires_approval" => "NO",
             "transactions" => [
               %{"name" => name, "account" => phone_number, "amount" => amount}
             ]
           }
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def check_send_money_status(tracking_id) do
    secret_key = System.get_env("INTASEND_SECRET_KEY")

    case Req.post("#{@base_url}/send-money/status/",
           headers: [{"authorization", "Bearer #{secret_key}"}],
           json: %{"tracking_id" => tracking_id}
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

end
