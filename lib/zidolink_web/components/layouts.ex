defmodule ZidolinkWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ZidolinkWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="drawer">
      <input id="nav-drawer" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col min-h-screen">
        <header class="navbar border-b border-base-300 px-4 sm:px-6 lg:px-8">
          <div class="flex-1 flex items-center gap-2">
            <label
              :if={@current_scope}
              for="nav-drawer"
              class="btn btn-ghost btn-sm btn-circle drawer-button"
              aria-label="Open menu"
            >
              <.icon name="hero-bars-3" class="size-5" />
            </label>

            <a
              href="/"
              class="inline-flex items-center whitespace-nowrap text-xl font-black tracking-tight"
            >
              <span class="text-[#241B2F]">ZIDO</span><span class="text-[#FF6F5E]">LINK</span>
            </a>
          </div>

          <div class="flex-none">
            <ul class="flex items-center gap-2">
              <li><.theme_toggle /></li>

              <%= if @current_scope do %>
                <li class="text-sm opacity-60 px-2 hidden sm:block">
                  {@current_scope.user.email}
                </li>

                <li>
                  <.link
                    href={~p"/users/settings"}
                    class="btn btn-ghost btn-sm"
                  >
                    Settings
                  </.link>
                </li>

                <li>
                  <.link
                    href={~p"/users/log-out"}
                    method="delete"
                    class="btn btn-ghost btn-sm"
                  >
                    Log out
                  </.link>
                </li>
              <% else %>
                <li>
                  <.link href={~p"/users/log-in"} class="btn btn-ghost btn-sm">
                    Log in
                  </.link>
                </li>

                <li>
                  <.link
                    href={~p"/users/register"}
                    class="btn btn-primary btn-sm"
                  >
                    Get Started
                  </.link>
                </li>
              <% end %>
            </ul>
          </div>
        </header>

        <main class="px-4 py-20 sm:px-6 lg:px-8 flex-1">
          <div class="mx-auto max-w-2xl space-y-4">
            {render_slot(@inner_block)}
          </div>
        </main>

        <.flash_group flash={@flash} />
      </div>

      <%!-- Sidebar drawer --%>
      <div :if={@current_scope} class="drawer-side z-50">
        <label
          for="nav-drawer"
          aria-label="close sidebar"
          class="drawer-overlay"
        />

        <aside class="flex min-h-full w-[85vw] max-w-72 flex-col bg-[#FFFCF6] px-4 py-5 text-[#241B2F]">

          <%!-- Brand + close button --%>
          <div class="flex items-center justify-between mb-6">
            <a
              href="/"
              class="inline-flex w-fit items-center whitespace-nowrap text-xl font-black tracking-tight"
            >
              <span class="text-[#241B2F]">ZIDO</span><span class="text-[#FF6F5E]">LINK</span>
            </a>

            <label
              for="nav-drawer"
              aria-label="close menu"
              class="btn btn-sm btn-circle border-2 border-[#FF6F5E] bg-transparent text-[#FF6F5E] hover:bg-[#FF6F5E] hover:text-white"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </label>
          </div>

          <%!-- Trainer navigation --%>
          <section
            :if={"trainer" in @current_scope.user.roles}
            class="mb-5 rounded-2xl bg-[#F5EDE2] p-3"
          >
            <p class="mb-2 px-3 text-[11px] font-bold uppercase tracking-[0.16em] text-[#8A7D78]">
              Trainer
            </p>

            <nav id="trainer-nav" phx-hook="ActiveNavLink" class="flex flex-col gap-1">
              <.link
                href={~p"/dashboard"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-home" class="size-5 text-[#776779]" />
                Dashboard
              </.link>

              <.link
                href={~p"/trainer/clients"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-users" class="size-5 text-[#776779]" />
                Clients
              </.link>

              <.link
                href={~p"/trainer/subscriptions"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-envelope" class="size-5 text-[#776779]" />
                Subscriptions
              </.link>

              <.link
                href={~p"/trainer/profile"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-identification" class="size-5 text-[#776779]" />
                Profile
              </.link>
            </nav>
          </section>

          <%!-- Client navigation --%>
          <section
            :if={"client" in @current_scope.user.roles}
            class="mb-5 rounded-2xl bg-[#F5EDE2] p-3"
          >
            <p class="mb-2 px-3 text-[11px] font-bold uppercase tracking-[0.16em] text-[#8A7D78]">
              Client
            </p>

            <nav id="client-nav" phx-hook="ActiveNavLink" class="flex flex-col gap-1">
              <.link
                href={~p"/dashboard"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-home" class="size-5 text-[#776779]" />
                Dashboard
              </.link>

              <.link
                href={~p"/client/meal-plan"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-cake" class="size-5 text-[#776779]" />
                Meal Plan
              </.link>

              <.link
                href={~p"/client/workout-plan"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-bolt" class="size-5 text-[#776779]" />
                Workout Plan
              </.link>

              <.link
                href={~p"/client/progress"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-chart-bar" class="size-5 text-[#776779]" />
                Progress
              </.link>

              <.link
                href={~p"/client/profile"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-identification" class="size-5 text-[#776779]" />
                Profile
              </.link>
            </nav>
          </section>

          <%!-- Seller navigation --%>
          <section
            :if={"seller" in @current_scope.user.roles}
            class="mb-5 rounded-2xl bg-[#F5EDE2] p-3"
          >
            <p class="mb-2 px-3 text-[11px] font-bold uppercase tracking-[0.16em] text-[#8A7D78]">
              Seller
            </p>

            <nav id="seller-nav" phx-hook="ActiveNavLink" class="flex flex-col gap-1">
              <.link
                href={~p"/dashboard"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-home" class="size-5 text-[#776779]" />
                Dashboard
              </.link>

              <.link
                href={~p"/seller/profile"}
                class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors hover:bg-[#EDE0D1]"
              >
                <.icon name="hero-identification" class="size-5 text-[#776779]" />
                Profile
              </.link>
            </nav>
          </section>

          <%!-- Keep logout at the bottom --%>
          <div class="flex-1"></div>

          <div class="mt-6 border-t border-[#EDE2D4] pt-4">
            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="flex items-center gap-3 rounded-xl bg-[#F5EDE2] px-4 py-3 text-sm font-semibold text-[#241B2F] transition-colors hover:bg-[#EDE0D1]"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="size-5" />
              Logout
            </.link>
          </div>
        </aside>
      </div>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="hidden sm:flex card relative flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>

    <div class="dropdown dropdown-end sm:hidden">
      <div tabindex="0" role="button" class="btn btn-ghost btn-sm btn-circle">
        <.icon name="hero-sun-micro" class="size-4" />
      </div>

      <ul
        tabindex="0"
        class="dropdown-content menu bg-base-100 rounded-box z-10 w-40 p-2 shadow border border-base-300"
      >
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="system"
          >
            <.icon name="hero-computer-desktop-micro" class="size-4" />
            System
          </button>
        </li>

        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="light"
          >
            <.icon name="hero-sun-micro" class="size-4" />
            Light
          </button>
        </li>

        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="dark"
          >
            <.icon name="hero-moon-micro" class="size-4" />
            Dark
          </button>
        </li>
      </ul>
    </div>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
