defmodule ZidolinkWeb.Admin.ApplicationLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.RoleApplications
  alias Zidolink.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <.header>Pending applications</.header>

        <div :if={@applications == []} class="mt-6 text-center text-base-content/60">
          Nothing pending right now.
        </div>

        <div :for={app <- @applications} class="mt-6 border rounded-lg p-4">
          <div class="flex justify-between items-start">
            <div>
              <p class="font-semibold">
                {app.user.email} &mdash; applying as {app.role}
              </p>
              <p class="text-sm text-base-content/60">
                Submitted {Calendar.strftime(app.inserted_at, "%d %b %Y, %H:%M")}
              </p>
            </div>
          </div>

          <div class="mt-3 space-y-1 text-sm">
            <p :for={{key, value} <- app.data} :if={key != "certificate_url"}>
              <span class="font-medium">{key}:</span> {value}
            </p>
            <p :if={app.data["certificate_url"]}>
              <span class="font-medium">certificate:</span>
              <a
                href={app.data["certificate_url"]}
                target="_blank"
                rel="noopener"
                class="link text-primary"
              >
                View certificate &rarr;
              </a>
            </p>
          </div>

          <div class="mt-4 flex gap-2">
            <.button phx-click="approve" phx-value-id={app.id} class="btn btn-primary btn-sm">
              Approve
            </.button>
            <.button phx-click="reject" phx-value-id={app.id} class="btn btn-error btn-sm">
              Reject
            </.button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, applications: load_applications())}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    application = Enum.find(socket.assigns.applications, &(&1.id == String.to_integer(id)))
    user = Accounts.get_user!(application.user_id)

    {:ok, _} =
      RoleApplications.update_application(application, %{
        status: "approved",
        reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    {:ok, _} =
      Accounts.update_user_roles(user, %{
        roles: user.roles ++ [application.role],
        pending_role_request: nil
      })

    {:noreply,
     socket
     |> put_flash(:info, "Approved #{user.email} as #{application.role}.")
     |> assign(applications: load_applications())}
  end

  def handle_event("reject", %{"id" => id}, socket) do
    application = Enum.find(socket.assigns.applications, &(&1.id == String.to_integer(id)))
    user = Accounts.get_user!(application.user_id)

    {:ok, _} =
      RoleApplications.update_application(application, %{
        status: "rejected",
        reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    {:ok, _} = Accounts.update_user_roles(user, %{pending_role_request: nil})

    {:noreply,
     socket
     |> put_flash(:info, "Rejected #{user.email}'s #{application.role} application.")
     |> assign(applications: load_applications())}
  end

  defp load_applications do
    RoleApplications.list_pending_applications()
    |> Zidolink.Repo.preload(:user)
  end
end
