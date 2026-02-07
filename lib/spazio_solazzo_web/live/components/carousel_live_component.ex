defmodule SpazioSolazzoWeb.CarouselLiveComponent do
  @moduledoc """
  A LiveComponent for image carousels with navigation controls.

  ## Configuration Options
  - `images`: List of image URLs (required)
  - `height`: Height of the carousel (default: "650px")
  """
  use Phoenix.LiveComponent

  import SpazioSolazzoWeb.CoreComponents, only: [icon: 1]

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:carousel_index, fn -> 0 end)
     |> assign_new(:height, fn -> "650px" end)}
  end

  @impl true
  def handle_event("carousel_next", _params, socket) do
    images_count = length(socket.assigns.images)
    new_index = rem(socket.assigns.carousel_index + 1, images_count)
    {:noreply, assign(socket, carousel_index: new_index)}
  end

  @impl true
  def handle_event("carousel_prev", _params, socket) do
    images_count = length(socket.assigns.images)
    new_index = rem(socket.assigns.carousel_index - 1 + images_count, images_count)
    {:noreply, assign(socket, carousel_index: new_index)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="relative carousel w-full"
      style={"height: #{@height};"}
    >
      <div
        class="flex h-full transition-transform duration-500 ease-in-out"
        style={"transform: translateX(-#{@carousel_index * 100}%);"}
      >
        <div :for={image <- @images} class="carousel-item w-full">
          <img
            src={image}
            class="w-full object-cover"
          />
        </div>
      </div>

      <button
        phx-click="carousel_prev"
        phx-target={@myself}
        aria-label="Previous image"
        class="absolute left-4 top-1/2 -translate-y-1/2 bg-white/20 hover:bg-white/40 backdrop-blur-sm p-2 rounded-full text-white transition-colors"
      >
        <.icon name="hero-chevron-left" class="w-6 h-6" />
      </button>
      <button
        phx-click="carousel_next"
        phx-target={@myself}
        aria-label="Next image"
        class="absolute right-4 top-1/2 -translate-y-1/2 bg-white/20 hover:bg-white/40 backdrop-blur-sm p-2 rounded-full text-white transition-colors"
      >
        <.icon name="hero-chevron-right" class="w-6 h-6" />
      </button>
    </div>
    """
  end
end
