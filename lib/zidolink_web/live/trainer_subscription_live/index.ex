defmodule ZidolinkWeb.TrainerSubscriptionLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.Subscriptions

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header>Requests</.header>

        <div :if={@requests == []} class="mt-6 text-center text-base-content/80">
          Nothing to act on right now.
        </div>

        <div :for={item <- @requests} class="mt-4 border rounded-lg p-4">
          <p class="font-semibold">
            {item.label} &mdash; {item.request.kind} subscription
          </p>
          <p :if={item.phone} class="text-sm text-base-content/60">
            {item.phone}
          </p>
          <p class="text-sm text-base-content/60">
            Requested {Calendar.strftime(item.request.inserted_at, "%d %b %Y, %H:%M")}
          </p>

          <p :if={item.request.status == "declined"} class="text-sm text-error mt-1">
            Previously declined<%= if item.request.decline_reason, do: " (#{item.request.decline_reason})" %>
          </p>

          <p :if={item.request.quote_history != []} class="text-xs text-base-content/60 mt-1">
            Past quotes: {Enum.map(item.request.quote_history, & &1["price"]) |> Enum.join(", ")} KES
          </p>

          <form phx-submit="set_quote" phx-value-id={item.request.id} class="mt-3 flex gap-2 items-end">
            <div>
              <label class="label text-xs">Quote price (KES)</label>
              <input type="number" name="price" class="input input-bordered input-sm w-32" required min="1" />
            </div>
            <.button class="btn btn-primary btn-sm">Send quote</.button>
          </form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Zidolink.PubSub, Subscriptions.trainer_subscriptions_topic(user.id))
    end

    {:ok, assign(socket, requests: load_requests(user.id))}
  end

  @impl true
  def handle_event("set_quote", %{"id" => id, "price" => price}, socket) do
    user = socket.assigns.current_scope.user
    item = Enum.find(socket.assigns.requests, &(&1.request.id == String.to_integer(id)))
    request = item.request
    is_requote = request.quote_history != []

    case Subscriptions.set_quote(request, String.to_integer(price)) do
      {:ok, updated} ->
        trainer_profile = Zidolink.Profiles.get_trainer_profile_by_user_id(user.id)
        settings = Zidolink.PlatformSettings.get_settings()

        Zidolink.Notifier.deliver_quote_notification(
          item.request.client.email,
          trainer_profile.display_name || user.email,
          updated.price + settings.platform_markup_fee,
          updated.kind,
          url(~p"/trainers/#{trainer_profile.id}"),
          is_requote
        )

        {:noreply,
         socket
         |> put_flash(:info, "Quote sent to #{item.request.client.email}.")
         |> assign(requests: load_requests(user.id))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Couldn't send the quote — please try again.")}
    end
  end

  @impl true
  def handle_info({:subscription_updated, _subscription}, socket) do
    user = socket.assigns.current_scope.user
    {:noreply, assign(socket, requests: load_requests(user.id))}
  end

  defp load_requests(trainer_id) do
    Subscriptions.list_actionable_requests_for_trainer(trainer_id)
    |> Enum.map(fn request ->
      profile = Zidolink.Profiles.get_client_profile_by_user_id(request.client_id)

      %{
        request: request,
        label: resolve_label(profile, request.client),
        phone: (profile && profile.phone_visible_to_trainers && request.client.phone) || nil
      }
    end)
  end

  defp resolve_label(profile, client) do
    case profile && profile.display_name do
      name when name not in [nil, ""] -> "#{name} (#{client.email})"
      _ -> client.email
    end
  end
end
