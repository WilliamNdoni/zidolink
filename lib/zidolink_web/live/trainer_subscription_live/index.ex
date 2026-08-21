defmodule ZidolinkWeb.TrainerSubscriptionLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.Subscriptions

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header>Subscription requests</.header>

        <div :if={@requests == []} class="mt-6 text-center text-base-content/80">
          Nothing to act on right now.
        </div>

        <div :for={request <- @requests} class="mt-4 border rounded-lg p-4">
          <p class="font-semibold">
            {request.client.email} &mdash; {request.kind} subscription
          </p>
          <p class="text-sm text-base-content/60">
            Requested {Calendar.strftime(request.inserted_at, "%d %b %Y, %H:%M")}
          </p>

          <p :if={request.status == "declined"} class="text-sm text-error mt-1">
            Previously declined<%= if request.decline_reason, do: " (#{request.decline_reason})" %>
          </p>

          <p :if={request.quote_history != []} class="text-xs text-base-content/60 mt-1">
            Past quotes: {Enum.map(request.quote_history, & &1["price"]) |> Enum.join(", ")} KES
          </p>

          <form phx-submit="set_quote" phx-value-id={request.id} class="mt-3 flex gap-2 items-end">
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
    {:ok, assign(socket, requests: Subscriptions.list_actionable_requests_for_trainer(user.id))}
  end

  @impl true
  def handle_event("set_quote", %{"id" => id, "price" => price}, socket) do
    user = socket.assigns.current_scope.user
    request = Enum.find(socket.assigns.requests, &(&1.id == String.to_integer(id)))

    case Subscriptions.set_quote(request, String.to_integer(price)) do
      {:ok, _updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Quote sent to #{request.client.email}.")
         |> assign(requests: Subscriptions.list_actionable_requests_for_trainer(user.id))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Couldn't send the quote — please try again.")}
    end
  end
end
