defmodule ZidolinkWeb.Admin.DashboardLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.{RoleApplications, Withdrawals}
  alias Zidolink.Payments.Intasend

  @poll_interval 3_000
  @poll_timeout_ms 90_000

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <.header>Platform earnings</.header>

        <div class="grid grid-cols-1 gap-4 mt-6">
          <div class="border rounded-lg p-4">
            <p class="text-sm text-base-content/60">Total earned (signup fees)</p>
            <p class="text-2xl font-bold">KES {@total_revenue}</p>
          </div>
          <div class="border rounded-lg p-4">
            <p class="text-sm text-base-content/60">Total withdrawn</p>
            <p class="text-2xl font-bold">KES {@total_withdrawn}</p>
          </div>
          <div class="border rounded-lg p-4 bg-base-200">
            <p class="text-sm text-base-content/60">Available to withdraw</p>
            <p class="text-2xl font-bold">KES {@available_balance}</p>
          </div>
        </div>

        <div class="mt-6 text-center">
          <%= cond do %>
            <% @pending_withdrawal -> %>
              <div class="flex flex-col items-center gap-2">
                <span class="loading loading-spinner loading-md"></span>
                <p class="text-sm text-base-content/60">
                  Sending KES {@pending_withdrawal.amount} to your phone&hellip;
                </p>
                <p :if={@poll_timed_out} class="text-error text-sm">
                  We didn't receive confirmation — check the withdrawals log below for its final status.
                </p>
              </div>
            <% is_nil(@current_scope.user.phone) -> %>
              <p class="text-error text-sm">
                Add a phone number in
                <.link href={~p"/users/settings"} class="link">Settings</.link>
                before withdrawing.
              </p>
            <% @available_balance < 10 -> %>
              <p class="text-sm text-base-content/60">Minimum withdrawal is KES 10.</p>
            <% true -> %>
              <.button phx-click="withdraw" class="btn btn-primary">
                Withdraw KES {@available_balance}
              </.button>
          <% end %>
        </div>

        <div class="mt-8">
          <.link href={~p"/admin/withdrawals"} class="link text-sm">
            View full withdrawal log &rarr;
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_balances(socket)}
  end

  @impl true
  def handle_event("withdraw", _params, socket) do
    user = socket.assigns.current_scope.user
    amount = socket.assigns.available_balance

    case Withdrawals.create_withdrawal(%{user_id: user.id, amount: amount}) do
      {:ok, withdrawal} ->
        {:noreply, trigger_withdrawal(socket, withdrawal, user)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Couldn't start the withdrawal — please try again.")}
    end
  end

  @impl true
  def handle_info(:poll_withdrawal_status, socket) do
    withdrawal = socket.assigns.pending_withdrawal

    cond do
      is_nil(withdrawal) ->
        {:noreply, socket}

      DateTime.compare(DateTime.utc_now(), socket.assigns.poll_deadline) == :gt ->
        {:noreply, assign(socket, poll_timed_out: true) |> load_balances()}

      true ->
        case Intasend.check_send_money_status(withdrawal.tracking_id) do
          {:ok, %{"transactions" => [%{"status" => "Successful", "provider_reference" => ref} | _]}} ->
            {:ok, _} =
              Withdrawals.update_withdrawal(withdrawal, %{
                status: "completed",
                provider_reference: ref,
                completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
              })

            {:noreply, load_balances(socket)}

          {:ok, %{"transactions" => [%{"status" => "Unsuccessful", "status_description" => reason} | _]}} ->
            {:ok, _} =
              Withdrawals.update_withdrawal(withdrawal, %{status: "failed", failure_reason: reason})

            {:noreply, load_balances(socket)}

          _ ->
            schedule_poll()
            {:noreply, socket}
        end
    end
  end

  defp trigger_withdrawal(socket, withdrawal, user) do
    name = String.replace(user.email, ~r/[^a-zA-Z0-9\s]/, "-")

    case Intasend.send_money(user.phone, withdrawal.amount, name) do
      {:ok, %{"tracking_id" => tracking_id}} ->
        {:ok, updated} = Withdrawals.update_withdrawal(withdrawal, %{tracking_id: tracking_id})

        deadline = DateTime.add(DateTime.utc_now(), @poll_timeout_ms, :millisecond)
        schedule_poll()

        assign(socket, pending_withdrawal: updated, poll_deadline: deadline, poll_timed_out: false)

      {:error, reason} ->
        Withdrawals.update_withdrawal(withdrawal, %{
          status: "failed",
          failure_reason: inspect(reason)
        })

        put_flash(socket, :error, "Couldn't start the withdrawal — please try again.")
        |> load_balances()
    end
  end

  defp load_balances(socket) do
    user = socket.assigns.current_scope.user
    total_revenue = RoleApplications.total_signup_revenue()
    total_withdrawn = Withdrawals.total_withdrawn(user.id)
    committed = Withdrawals.total_committed(user.id)

    assign(socket,
      total_revenue: total_revenue,
      total_withdrawn: total_withdrawn,
      available_balance: total_revenue - committed,
      pending_withdrawal: nil
    )
  end

  defp schedule_poll do
    Process.send_after(self(), :poll_withdrawal_status, @poll_interval)
  end
end
