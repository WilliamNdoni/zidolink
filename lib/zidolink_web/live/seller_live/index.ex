defmodule ZidolinkWeb.SellerLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.Profiles

  @default_radius_km 5

  @category_labels %{
    "nutrition" => "Nutrition",
    "equipment" => "Gym equipment",
    "wear" => "Gym wear",
    "accessories" => "Accessories",
    "recovery" => "Recovery & wellness"
  }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <.header>Find a seller</.header>

        <form phx-change="search" class="mt-4">
          <input
            type="text"
            name="q"
            value={@query}
            placeholder="Search by shop name, bio, or category..."
            class="input input-bordered w-full"
            autocomplete="off"
          />
        </form>

        <div class="mt-4">
          <div id="location-picker" phx-hook="LocationPicker" data-api-key={@google_maps_api_key} class="relative">
            <input
              type="text"
              id="location-search-input"
              placeholder="Search a location to find sellers near you..."
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

          <form :if={@near_lat} phx-change="change_radius" class="mt-2">
            <select name="radius" class="select select-bordered select-sm">
              <option value="3" selected={@radius_km == 3}>Within 3km</option>
              <option value="5" selected={@radius_km == 5}>Within 5km</option>
              <option value="10" selected={@radius_km == 10}>Within 10km</option>
              <option value="25" selected={@radius_km == 25}>Within 25km</option>
              <option value="50" selected={@radius_km == 50}>Within 50km</option>
            </select>
          </form>

          <p :if={@near_location} class="text-sm text-base-content/80 mt-2 flex items-center gap-1">
            <.icon name="hero-map-pin" class="size-4" />
            Showing sellers within {@radius_km}km of {@near_location}
            <button type="button" phx-click="clear_near_me" class="btn btn-outline btn-secondary btn-xs ml-2">
              Clear
            </button>
          </p>
        </div>

        <div :if={@sellers == []} class="mt-6 text-center text-base-content/80">
          No sellers found.
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-6">
          <div :for={seller <- @sellers} class="border rounded-lg p-4">
            <img
              :if={seller.photo_url}
              src={seller.photo_url}
              class="size-16 rounded-full object-cover mb-2"
            />
            <h3 class="font-semibold">{seller.shop_name}</h3>
            <p :if={seller.bio} class="text-sm text-base-content/80 mt-1">{seller.bio}</p>
            <div class="flex flex-wrap gap-1 mt-2">
              <span :for={c <- seller.categories} class="badge badge-outline">
                {@category_labels[c] || c}
              </span>
            </div>
            <p :if={seller.location_address} class="text-sm text-base-content/80 mt-2 flex items-center gap-1">
              <.icon name="hero-map-pin" class="size-4" />
              {seller.location_address}
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
    sellers = Profiles.search_seller_profiles(nil, 1)

    {:ok,
     assign(socket,
       sellers: sellers,
       query: "",
       page: 1,
       has_more: length(sellers) == 12,
       near_lat: nil,
       near_lng: nil,
       near_location: nil,
       radius_km: @default_radius_km,
       category_labels: @category_labels,
       google_maps_api_key: System.get_env("GOOGLE_MAPS_API_KEY")
     )}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    sellers = Profiles.search_seller_profiles(query, 1)
    {:noreply, assign(socket, sellers: sellers, query: query, page: 1, has_more: length(sellers) == 12)}
  end

  def handle_event("location_selected", params, socket) do
    radius = socket.assigns.radius_km
    sellers = Profiles.nearby_seller_profiles(params["lat"], params["lng"], radius, 1)

    {:noreply,
     assign(socket,
       sellers: sellers,
       near_lat: params["lat"],
       near_lng: params["lng"],
       near_location: params["address"] || "your location",
       page: 1,
       has_more: length(sellers) == 12
     )}
  end

  def handle_event("change_radius", %{"radius" => radius_str}, socket) do
    radius = String.to_integer(radius_str)

    sellers =
      Profiles.nearby_seller_profiles(socket.assigns.near_lat, socket.assigns.near_lng, radius, 1)

    {:noreply,
     assign(socket, sellers: sellers, radius_km: radius, page: 1, has_more: length(sellers) == 12)}
  end

  def handle_event("clear_near_me", _params, socket) do
    sellers = Profiles.search_seller_profiles(socket.assigns.query, 1)

    {:noreply,
     assign(socket,
       sellers: sellers,
       near_lat: nil,
       near_lng: nil,
       near_location: nil,
       radius_km: @default_radius_km,
       page: 1,
       has_more: length(sellers) == 12
     )}
  end

  def handle_event("load_more", _params, socket) do
    next_page = socket.assigns.page + 1

    more_sellers =
      if socket.assigns.near_lat do
        Profiles.nearby_seller_profiles(
          socket.assigns.near_lat,
          socket.assigns.near_lng,
          socket.assigns.radius_km,
          next_page
        )
      else
        Profiles.search_seller_profiles(socket.assigns.query, next_page)
      end

    {:noreply,
     assign(socket,
       sellers: socket.assigns.sellers ++ more_sellers,
       page: next_page,
       has_more: length(more_sellers) == 12
     )}
  end
end
