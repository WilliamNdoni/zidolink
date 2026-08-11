defmodule Zidolink.Media.HeroImagesCache do
  use GenServer
  alias Zidolink.Media.Unsplash

  @queries ["bodybuilder training", "healthy meal", "running cardio"]
  @refresh_interval :timer.hours(6)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def get_images, do: GenServer.call(__MODULE__, :get_images)

  @impl true
  def init(_state) do
    send(self(), :refresh)
    {:ok, %{images: []}}
  end

  @impl true
  def handle_call(:get_images, _from, state), do: {:reply, state.images, state}

  @impl true
  def handle_info(:refresh, state) do
    images =
      @queries
      |> Enum.map(&Unsplash.fetch/1)
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, image} -> image end)

    images = if images == [], do: state.images, else: images

    Process.send_after(self(), :refresh, @refresh_interval)
    {:noreply, %{state | images: images}}
  end
end
