defmodule ZidolinkWeb.TrainerLive.Show do
  use ZidolinkWeb, :live_view

  alias Zidolink.Profiles

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
            Payments are currently supported via M-Pesa (Safaricom) only.
          </p>
          <.link
            href={~p"/users/register?return_to=/trainers/#{@trainer.id}"}
            class="btn btn-primary w-full"
          >
            Book a session or subscribe
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    trainer = Profiles.get_trainer_profile(id)
    {:ok, assign(socket, trainer: trainer)}
  end
end
