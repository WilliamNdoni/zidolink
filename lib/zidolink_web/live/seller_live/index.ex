defmodule ZidolinkWeb.SellerLive.Index do
  use ZidolinkWeb, :live_view

  alias Zidolink.Profiles

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

        <div :if={@sellers == []} class="mt-6 text-center text-base-content/80">
          No sellers listed yet — check back soon.
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
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, sellers: Profiles.list_completed_seller_profiles(), category_labels: @category_labels)}
  end
end
