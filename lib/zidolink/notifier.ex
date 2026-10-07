defmodule Zidolink.Notifier do
  import Swoosh.Email
  alias Zidolink.Mailer

  defp deliver(to, subject, body) do
    email =
      new()
      |> to(to)
      |> from({"ZidoLink", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver_subscription_request(trainer_email, client_email, kind, url) do
    deliver(trainer_email, "New #{kind} subscription request", """
    #{client_email} has requested a #{kind} subscription with you on ZidoLink.

    Review it and set a price here:
    #{url}
    """)
  end

  def deliver_quote_notification(client_email, trainer_name, price, kind, url) do
    deliver(client_email, "#{trainer_name} sent you a price quote", """
    #{trainer_name} has sent you a quote of KES #{price} for a #{kind} subscription.

    View it and pay or decline here:
    #{url}
    """)
  end
end
