defmodule ZidolinkWeb.TrainerLive.Show do
  use ZidolinkWeb, :live_view

  alias Zidolink.Profiles
  alias Zidolink.Subscriptions
  alias Zidolink.Payments.Intasend

  @poll_interval 3_000
  @poll_timeout_ms 90_000

  @decline_reasons [
    {"Prefer not to say", "prefer_not_to_say"},
    {"Price too high", "price_too_high"},
    {"Other", "other"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <div class="text-center">
          <img
            :if={@trainer.photo_url}
            src={@trainer.photo_url}
            class="size-24 rounded-full object-cover mx-auto mb-3"
          />
          <h1 class="text-xl font-bold">{@trainer.display_name}</h1>
          <p class="text-sm text-base-content/80 mt-2">{@trainer.bio}</p>
          <div class="flex flex-wrap justify-center gap-1 mt-3">
            <span :for={s <- @trainer.specialties} class="badge badge-outline">{s}</span>
          </div>
          <p :if={@trainer.location_address} class="text-sm text-base-content/80 mt-3 flex items-center justify-center gap-1">
            <.icon name="hero-map-pin" class="size-4" />
            {@trainer.location_address}
          </p>
        </div>

        <div class="mt-8 border rounded-lg p-4">
          <p class="text-sm text-base-content/60 mb-3">
            Payments are currently supported via M-Pesa only.
          </p>

          <%= cond do %>
            <% is_nil(@current_user) -> %>
              <.link
                href={~p"/users/register?return_to=/trainers/#{@trainer.id}"}
                class="btn btn-primary w-full"
              >
                Book a session or subscribe
              </.link>
            <% is_nil(@trainer.session_price) -> %>
              <p class="text-sm text-base-content/60">
                This trainer isn't currently offering one-time sessions.
              </p>
            <% @booking && @booking.status == "awaiting_payment" -> %>
              <div class="text-center">
                <p class="text-sm mb-2">
                  Confirm KES {@booking.price + @platform_markup_fee} on your phone.
                </p>
                <div :if={!@poll_timed_out}><span class="loading loading-spinner loading-md"></span></div>
                <p :if={@poll_timed_out} class="text-error text-sm mt-2">
                  We didn't receive confirmation — this sometimes happens. You can try again.
                </p>
                <.button :if={@poll_timed_out} phx-click="retry_booking" class="btn btn-primary btn-sm mt-2">
                  Try again
                </.button>
              </div>
            <% @booking && @booking.status == "active" -> %>
              <p class="text-sm text-success">
                Session booked and paid — {@trainer.display_name} will be in touch to confirm timing.
              </p>
            <% true -> %>
              <p class="text-sm text-base-content/80 mb-2">
                Book a one-time session with {@trainer.display_name}.
              </p>
              <.button phx-click="book_session" class="btn btn-primary w-full">
                Book a session — KES {@trainer.session_price + @platform_markup_fee}
              </.button>
          <% end %>
        </div>

        <div :if={@current_user} class="mt-4 border rounded-lg p-4">
          <h3 class="font-semibold text-sm mb-1">Subscribe to this trainer</h3>
          <p class="text-sm text-base-content/60 mb-2">
            Send a request and {@trainer.display_name} will send you a price quote. You can accept and pay, or decline if it's not right for you.
          </p>

          <%= cond do %>
            <% @subscription_request && @subscription_request.status == "pending_quote" -> %>
              <p class="text-sm text-base-content/80">
                Your {@subscription_request.kind} subscription request has been sent — {@trainer.display_name} will send you a price soon.
              </p>
            <% @subscription_request && @subscription_request.status == "awaiting_payment" -> %>
              <div>
                <p class="text-sm text-base-content/80 mb-2">
                  You've been quoted KES {@subscription_request.price + @platform_markup_fee} for a {@subscription_request.kind} subscription.
                </p>

                <%= if @sub_pending_payment do %>
                  <div class="text-center">
                    <p class="text-sm mb-2">Confirm KES {@subscription_request.price + @platform_markup_fee} on your phone.</p>
                    <div :if={!@sub_poll_timed_out}><span class="loading loading-spinner loading-md"></span></div>
                    <p :if={@sub_poll_timed_out} class="text-error text-sm mt-2">
                      We didn't receive confirmation — this sometimes happens. You can try again.
                    </p>
                    <.button :if={@sub_poll_timed_out} phx-click="retry_subscription_payment" class="btn btn-primary btn-sm mt-2">
                      Try again
                    </.button>
                  </div>
                <% else %>
                  <div class="flex gap-2">
                    <.button phx-click="pay_subscription" class="btn btn-primary btn-sm">
                      Pay KES {@subscription_request.price + @platform_markup_fee}
                    </.button>
                    <.button phx-click="show_decline_form" class="btn btn-outline btn-sm">
                      Decline
                    </.button>
                  </div>

                  <form :if={@show_decline_form} phx-submit="decline_quote" class="mt-3">
                    <select name="reason" class="select select-bordered select-sm w-full">
                      <option :for={{label, value} <- @decline_reasons} value={value}>{label}</option>
                    </select>
                    <input
                      type="text"
                      name="reason_text"
                      placeholder="Tell the trainer why (optional)"
                      class="input input-bordered input-sm w-full mt-2"
                    />
                    <.button class="btn btn-outline btn-error btn-sm w-full mt-2">
                      Confirm decline
                    </.button>
                  </form>
                <% end %>
              </div>
            <% @subscription_request && @subscription_request.status == "declined" -> %>
              <p class="text-sm text-base-content/80 mb-2">
                Your last request wasn't taken forward<%= if @subscription_request.decline_reason, do: " (#{@subscription_request.decline_reason})" %>. You can request again.
              </p>
              <div class="flex gap-2">
                <.button phx-click="request_subscription" phx-value-kind="weekly" class="btn btn-primary btn-sm">
                  Request weekly
                </.button>
                <.button phx-click="request_subscription" phx-value-kind="monthly" class="btn btn-primary btn-sm">
                  Request monthly
                </.button>
              </div>
            <% @subscription_request && @subscription_request.status == "active" -> %>
              <p class="text-sm text-success">You have an active {@subscription_request.kind} subscription.</p>
            <% true -> %>
              <div class="flex gap-2">
                <.button phx-click="request_subscription" phx-value-kind="weekly" class="btn btn-primary btn-sm">
                  Request weekly
                </.button>
                <.button phx-click="request_subscription" phx-value-kind="monthly" class="btn btn-primary btn-sm">
                  Request monthly
                </.button>
              </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    trainer = Profiles.get_trainer_profile(id)
    user = (socket.assigns[:current_scope] && socket.assigns.current_scope.user) || nil
    settings = Zidolink.PlatformSettings.get_settings()

    {booking, subscription_request, poll_deadline} =
      if user do
        booking = Subscriptions.get_latest_one_time_booking(user.id, trainer.user_id)
        sub_request = Subscriptions.get_latest_subscription_request(user.id, trainer.user_id)

        deadline =
          if booking && booking.status == "awaiting_payment" do
            if connected?(socket), do: schedule_poll(:poll_booking_status)
            DateTime.add(DateTime.utc_now(), @poll_timeout_ms, :millisecond)
          end

        {booking, sub_request, deadline}
      else
        {nil, nil, nil}
      end

    {:ok,
     assign(socket,
       trainer: trainer,
       current_user: user,
       booking: booking,
       subscription_request: subscription_request,
       poll_deadline: poll_deadline,
       poll_timed_out: false,
       sub_pending_payment: false,
       sub_poll_deadline: nil,
       sub_poll_timed_out: false,
       show_decline_form: false,
       decline_reasons: @decline_reasons,
       platform_markup_fee: settings.platform_markup_fee
     )}
  end

  @impl true
  def handle_event("book_session", _params, socket) do
    user = socket.assigns.current_user
    trainer = socket.assigns.trainer

    case Subscriptions.book_one_time_session(user.id, trainer.user_id, trainer.session_price) do
      {:ok, booking} ->
        {:noreply, trigger_booking_payment(socket, booking, user)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Couldn't start the booking — please try again.")}
    end
  end

  def handle_event("retry_booking", _params, socket) do
    user = socket.assigns.current_user
    {:noreply, socket |> assign(poll_timed_out: false) |> trigger_booking_payment(socket.assigns.booking, user)}
  end

  def handle_event("request_subscription", %{"kind" => kind}, socket) do
    user = socket.assigns.current_user
    trainer = socket.assigns.trainer

    case Subscriptions.request_subscription(user.id, trainer.user_id, kind) do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Your #{kind} subscription request was sent.")
         |> assign(subscription_request: request)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Couldn't send the request — please try again.")}
    end
  end

  def handle_event("pay_subscription", _params, socket) do
    user = socket.assigns.current_user
    {:noreply, trigger_subscription_payment(socket, socket.assigns.subscription_request, user)}
  end

  def handle_event("retry_subscription_payment", _params, socket) do
    user = socket.assigns.current_user

    {:noreply,
     socket
     |> assign(sub_poll_timed_out: false)
     |> trigger_subscription_payment(socket.assigns.subscription_request, user)}
  end

  def handle_event("show_decline_form", _params, socket) do
    {:noreply, assign(socket, show_decline_form: true)}
  end

  def handle_event("decline_quote", %{"reason" => reason, "reason_text" => reason_text}, socket) do
    label =
      case reason do
        "prefer_not_to_say" -> "Prefer not to say"
        "price_too_high" -> "Price too high"
        "other" -> if reason_text != "", do: reason_text, else: "Other"
        _ -> reason
      end

    case Subscriptions.decline_quote(socket.assigns.subscription_request, label) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Request declined.")
         |> assign(subscription_request: updated, show_decline_form: false)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Something went wrong — please try again.")}
    end
  end

  @impl true
  def handle_info(:poll_booking_status, socket) do
    booking = socket.assigns.booking

    cond do
      is_nil(booking) or is_nil(booking.invoice_id) ->
        {:noreply, socket}

      DateTime.compare(DateTime.utc_now(), socket.assigns.poll_deadline) == :gt ->
        {:ok, updated} = Subscriptions.update_subscription(booking, %{status: "expired"})
        {:noreply, assign(socket, booking: updated, poll_timed_out: true)}

      true ->
        case Intasend.check_status(booking.invoice_id) do
          {:ok, %{"invoice" => %{"state" => "COMPLETE"}}} ->
            {:ok, updated} = Subscriptions.update_subscription(booking, %{status: "active"})
            {:noreply, assign(socket, booking: updated)}

          {:ok, %{"invoice" => %{"state" => "FAILED"}}} ->
            {:ok, updated} = Subscriptions.update_subscription(booking, %{status: "expired"})
            {:noreply, assign(socket, booking: updated, poll_timed_out: true)}

          _ ->
            schedule_poll(:poll_booking_status)
            {:noreply, socket}
        end
    end
  end

  def handle_info(:poll_subscription_status, socket) do
    request = socket.assigns.subscription_request

    cond do
      is_nil(request) or is_nil(request.invoice_id) ->
        {:noreply, socket}

      DateTime.compare(DateTime.utc_now(), socket.assigns.sub_poll_deadline) == :gt ->
        {:noreply, assign(socket, sub_poll_timed_out: true)}

      true ->
        case Intasend.check_status(request.invoice_id) do
          {:ok, %{"invoice" => %{"state" => "COMPLETE"}}} ->
            {days, _} = period_for_kind(request.kind)
            starts_at = DateTime.utc_now() |> DateTime.truncate(:second)
            ends_at = DateTime.add(starts_at, days, :day)

            {:ok, updated} =
              Subscriptions.update_subscription(request, %{
                status: "active",
                starts_at: starts_at,
                ends_at: ends_at
              })

            {:noreply, assign(socket, subscription_request: updated, sub_pending_payment: false)}

          {:ok, %{"invoice" => %{"state" => "FAILED"}}} ->
            {:noreply, assign(socket, sub_poll_timed_out: true)}

          _ ->
            schedule_poll(:poll_subscription_status)
            {:noreply, socket}
        end
    end
  end

  defp trigger_booking_payment(socket, booking, user) do
    total = booking.price + socket.assigns.platform_markup_fee
    api_ref = "booking-#{booking.id}"

    case Intasend.stk_push(user.phone, total, api_ref) do
      {:ok, %{"invoice" => %{"invoice_id" => invoice_id}}} ->
        {:ok, updated} = Subscriptions.update_subscription(booking, %{invoice_id: invoice_id})
        deadline = DateTime.add(DateTime.utc_now(), @poll_timeout_ms, :millisecond)
        schedule_poll(:poll_booking_status)
        assign(socket, booking: updated, poll_deadline: deadline, poll_timed_out: false)

      {:error, _reason} ->
        put_flash(socket, :error, "We couldn't start the payment request — please try again.")
    end
  end

  defp trigger_subscription_payment(socket, request, user) do
    total = request.price + socket.assigns.platform_markup_fee
    api_ref = "subscription-#{request.id}"

    case Intasend.stk_push(user.phone, total, api_ref) do
      {:ok, %{"invoice" => %{"invoice_id" => invoice_id}}} ->
        {:ok, updated} = Subscriptions.update_subscription(request, %{invoice_id: invoice_id})
        deadline = DateTime.add(DateTime.utc_now(), @poll_timeout_ms, :millisecond)
        schedule_poll(:poll_subscription_status)

        assign(socket,
          subscription_request: updated,
          sub_pending_payment: true,
          sub_poll_deadline: deadline,
          sub_poll_timed_out: false
        )

      {:error, _reason} ->
        put_flash(socket, :error, "We couldn't start the payment request — please try again.")
    end
  end

  defp period_for_kind("weekly"), do: {7, :day}
  defp period_for_kind("monthly"), do: {30, :day}
  defp period_for_kind(_), do: {30, :day}

  defp schedule_poll(message) do
    Process.send_after(self(), message, @poll_interval)
  end
end
