defmodule ZidolinkWeb.DashboardLive.Index do
  use ZidolinkWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg text-center">
        <.header>Welcome, {@current_scope.user.email}</.header>
        <p class="mt-4 text-base-content/60">
          Your dashboard is coming together — check back soon for more here.
        </p>
      </div>
    </Layouts.app>
    """
  end
end
