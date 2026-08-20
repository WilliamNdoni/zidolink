defmodule ZidolinkWeb.TrainerLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.Profiles

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <.header>Find a trainer</.header>

        <div :if={@trainers == []} class="mt-6 text-center text-base-content/80">
          No trainers listed yet — check back soon.
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-6">
          <div :for={trainer <- @trainers} class="border rounded-lg p-4">
            <img
              :if={trainer.photo_url}
              src={trainer.photo_url}
              class="size-16 rounded-full object-cover mb-2"
            />
            <h3 class="font-semibold">{trainer.display_name}</h3>
            <p class="text-sm text-base-content/80 mt-1">{trainer.bio}</p>
            <div class="flex flex-wrap gap-1 mt-2">
              <span :for={s <- trainer.specialties} class="badge badge-outline">{s}</span>
            </div>
            <p :if={trainer.location_address} class="text-sm text-base-content/80 mt-2 flex items-center gap-1">
              <.icon name="hero-map-pin" class="size-4" />
              {trainer.location_address}
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, trainers: Profiles.list_completed_trainer_profiles())}
  end
end
