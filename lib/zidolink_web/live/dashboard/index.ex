defmodule ZidolinkWeb.DashboardLive.Index do
  use ZidolinkWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <.header>Welcome, {@current_scope.user.email}</.header>

        <div :if={"client" in @current_scope.user.roles} class="mt-6 border rounded-lg p-4">
          <h3 class="font-semibold">As a client</h3>
          <p class="text-sm text-base-content/80 mt-1">
            Browsing and subscribing to trainers is coming soon — check back here once it's live.
          </p>
        </div>

        <div :if={"trainer" in @current_scope.user.roles} class="mt-6 border rounded-lg p-4">
          <h3 class="font-semibold">As a trainer</h3>
          <p class="text-sm text-base-content/80 mt-1">
            Setting up your public profile (bio, photo, location) is coming soon.
          </p>
        </div>

        <div :if={"seller" in @current_scope.user.roles} class="mt-6 border rounded-lg p-4">
          <h3 class="font-semibold">As a seller</h3>
          <p class="text-sm text-base-content/80 mt-1">
            Setting up your shop profile and listing products is coming soon.
          </p>
        </div>

        <div :if={@current_scope.user.roles == []} class="mt-6 text-center text-base-content/80">
          Nothing to show yet.
        </div>
      </div>
    </Layouts.app>
    """
  end
end
