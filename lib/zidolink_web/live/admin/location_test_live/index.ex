defmodule ZidolinkWeb.Admin.LocationTestLive.Index do
  use ZidolinkWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <.header>Location picker test</.header>

        <style>
          #autocomplete-container { position: relative; }
          :root {
            --gmp-mat-color-surface: #FFFBF3;
            --gmp-mat-color-on-surface: #241B2F;
            --gmp-mat-color-on-surface-variant: #6B6478;
            --gmp-mat-color-primary: #FF6F5E;
            --gmp-mat-color-outline-decorative: #F1E7D6;
          }
        </style>

        <div id="location-picker" phx-hook="LocationPicker" data-api-key={@google_maps_api_key} class="mt-6 relative">
          <input
            type="text"
            id="location-search-input"
            placeholder="Search for a location..."
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

        <div :if={@selected_location} class="mt-6 border rounded-lg p-4">
          <p><span class="font-medium">Lat:</span> {@selected_location.lat}</p>
          <p><span class="font-medium">Lng:</span> {@selected_location.lng}</p>
          <p :if={@selected_location.address}>
            <span class="font-medium">Address:</span> {@selected_location.address}
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       google_maps_api_key: System.get_env("GOOGLE_MAPS_API_KEY"),
       selected_location: nil
     )}
  end

  @impl true
  def handle_event("location_selected", params, socket) do
    {:noreply,
     assign(socket,
       selected_location: %{lat: params["lat"], lng: params["lng"], address: params["address"]}
     )}
  end
end
