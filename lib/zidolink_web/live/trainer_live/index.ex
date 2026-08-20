defmodule ZidolinkWeb.TrainerLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.Profiles

  @default_radius_km 25

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <.header>Find a trainer</.header>

        <form phx-change="search" class="mt-4">
          <input
            type="text"
            name="q"
            value={@query}
            placeholder="Search by name, bio, or specialty..."
            class="input input-bordered w-full"
            autocomplete="off"
          />
        </form>

        <div class="mt-4">
          <div id="location-picker" phx-hook="LocationPicker" data-api-key={@google_maps_api_key} class="relative">
            <input
              type="text"
              id="location-search-input"
              placeholder="Search a location to find trainers near you..."
              class="input input-bordered w-full"
              autocomplete="off"
            />
            <ul
              id="location-results"
              class="absolute z-10 w-full bg-base-100 border border-base-300 rounded-lg mt-1 shadow-lg"
            >
            </ul>
            <button type="button" id="use-current-location" class="btn btn-secondary btn-sm mt-3">
              Use my current location
            </button>
          </div>
          <p :if={@near_location} class="text-sm text-base-content/80 mt-2 flex items-center gap-1">
            <.icon name="hero-map-pin" class="size-4" />
            Showing trainers within {@default_radius_km}km of {@near_location}
            <button type="button" phx-click="clear_near_me" class="btn btn-outline btn-secondary btn-xs ml-2">
              Clear
            </button>
          </p>
        </div>

        <div :if={@trainers == []} class="mt-6 text-center text-base-content/80">
          No trainers found.
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

        <div :if={@has_more} class="mt-6 text-center">
          <.button phx-click="load_more" class="btn btn-secondary">Load more</.button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    trainers = Profiles.search_trainer_profiles(nil, 1)

    {:ok,
     assign(socket,
       trainers: trainers,
       query: "",
       page: 1,
       has_more: length(trainers) == 12,
       near_lat: nil,
       near_lng: nil,
       near_location: nil,
       default_radius_km: @default_radius_km,
       google_maps_api_key: System.get_env("GOOGLE_MAPS_API_KEY")
     )}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    trainers = Profiles.search_trainer_profiles(query, 1)
    {:noreply, assign(socket, trainers: trainers, query: query, page: 1, has_more: length(trainers) == 12)}
  end

  def handle_event("location_selected", params, socket) do
    trainers =
      Profiles.nearby_trainer_profiles(params["lat"], params["lng"], @default_radius_km, 1)

    {:noreply,
     assign(socket,
       trainers: trainers,
       near_lat: params["lat"],
       near_lng: params["lng"],
       near_location: params["address"] || "your location",
       page: 1,
       has_more: length(trainers) == 12
     )}
  end

  def handle_event("clear_near_me", _params, socket) do
    trainers = Profiles.search_trainer_profiles(socket.assigns.query, 1)

    {:noreply,
     assign(socket,
       trainers: trainers,
       near_lat: nil,
       near_lng: nil,
       near_location: nil,
       page: 1,
       has_more: length(trainers) == 12
     )}
  end

  def handle_event("load_more", _params, socket) do
    next_page = socket.assigns.page + 1

    more_trainers =
      if socket.assigns.near_lat do
        Profiles.nearby_trainer_profiles(
          socket.assigns.near_lat,
          socket.assigns.near_lng,
          @default_radius_km,
          next_page
        )
      else
        Profiles.search_trainer_profiles(socket.assigns.query, next_page)
      end

    {:noreply,
     assign(socket,
       trainers: socket.assigns.trainers ++ more_trainers,
       page: next_page,
       has_more: length(more_trainers) == 12
     )}
  end
end
