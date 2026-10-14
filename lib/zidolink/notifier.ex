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

  def deliver_quote_notification(client_email, trainer_name, price, kind, url, is_requote \\ false) do
    {subject, intro} =
      if is_requote do
        {"#{trainer_name} sent you a new price quote",
         "#{trainer_name} has sent you a new quote of KES #{price} for a #{kind} subscription."}
      else
        {"#{trainer_name} sent you a price quote",
         "#{trainer_name} has sent you a quote of KES #{price} for a #{kind} subscription."}
      end

    deliver(client_email, subject, """
    #{intro}

    View it and pay or decline here:
    #{url}
    """)
  end

  def deliver_takeover_requested(client_email, trainer_name, url) do
    deliver(client_email, "#{trainer_name} wants to manage your meal plan", """
    #{trainer_name} has requested to take over managing your meal plan.

    Review and respond here:
    #{url}
    """)
  end

  def deliver_takeover_approved(trainer_email, client_email, url) do
    deliver(trainer_email, "You now manage #{client_email}'s meal plan", """
    Your request to take over #{client_email}'s meal plan has been approved.

    View and edit it here:
    #{url}
    """)
  end

  def deliver_takeover_declined(trainer_email, client_email) do
    deliver(trainer_email, "Meal plan request declined", """
    #{client_email} has declined your request to take over their meal plan.
    """)
  end

  def deliver_meal_plan_ready(client_email, trainer_name, url) do
    deliver(client_email, "#{trainer_name} has set up your meal plan", """
    #{trainer_name} has set up your meal plan on ZidoLink.

    View it here:
    #{url}
    """)
  end

end
