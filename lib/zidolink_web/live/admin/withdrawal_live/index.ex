defmodule ZidolinkWeb.Admin.WithdrawalLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.Withdrawals

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <.header>Withdrawal log</.header>

        <div :if={@withdrawals == []} class="mt-6 text-center text-base-content/60">
          No withdrawals yet.
        </div>

        <div :for={w <- @withdrawals} class="mt-4 border rounded-lg p-4">
          <p class="font-semibold">{w.user.email} &mdash; KES {w.amount}</p>
          <p class="text-sm text-base-content/60">
            {String.capitalize(w.status)} &middot; {ZidolinkWeb.TimeHelpers.format_eat(w.inserted_at)}
          </p>
          <p :if={w.provider_reference} class="text-sm text-base-content/60">
            Ref: {w.provider_reference}
          </p>
          <p :if={w.failure_reason} class="text-sm text-error">{w.failure_reason}</p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, withdrawals: Withdrawals.list_all_withdrawals())}
  end
end
