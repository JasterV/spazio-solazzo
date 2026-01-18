defmodule SpazioSolazzoWeb.LandingComponents do
  @moduledoc """
  Reusable components for landing pages (coworking, meeting room, music room).
  """
  use Phoenix.Component

  import SpazioSolazzoWeb.CoreComponents, only: [icon: 1, back_to_link: 1]
  import Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: SpazioSolazzoWeb.Endpoint,
    router: SpazioSolazzoWeb.Router,
    statics: SpazioSolazzoWeb.static_paths()

  @doc """
  Renders a feature card with icon, title, and description.

  ## Examples

      <.feature_card
        icon="tv"
        title="4K Presentation"
        description="Crystal clear 65&quot; monitor ready for your slide decks."
        color="sky"
      />
  """
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true

  attr :color, :string,
    default: "sky",
    doc: "Color scheme: sky, orange, yellow, emerald, indigo, purple"

  def feature_card(assigns) do
    ~H"""
    <div class="card bg-base-100 p-8 rounded-2xl border border-base-200 shadow-sm hover:shadow-lg hover:border-primary/30 transition-all duration-300 group">
      <div class={[
        "w-12 h-12 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform",
        color_classes(@color)
      ]}>
        <.icon name={@icon} class="w-7 h-7" />
      </div>
      <h3 class="text-xl font-bold text-base-content mb-3">
        {@title}
      </h3>
      <p class="text-neutral leading-relaxed">
        {@description}
      </p>
    </div>
    """
  end

  defp color_classes("primary"), do: "bg-primary/10 text-primary"
  defp color_classes("secondary"), do: "bg-secondary/10 text-secondary"
  defp color_classes("accent"), do: "bg-accent/10 text-accent"
  defp color_classes("sky"), do: "bg-secondary/10 text-secondary"
  defp color_classes("orange"), do: "bg-primary/10 text-primary"
  defp color_classes("yellow"), do: "bg-accent/10 text-accent"
  defp color_classes("emerald"), do: "bg-success/10 text-success"
  defp color_classes("indigo"), do: "bg-info/10 text-info"
  defp color_classes("purple"), do: "bg-primary/10 text-primary"
  defp color_classes(_), do: "bg-neutral/10 text-neutral"

  @doc """
  Renders a house rules section with a list of rules.

  ## Examples

      <.house_rules title="House Rules">
        <:rule>Please clean the whiteboard after use.</:rule>
        <:rule>Outside food is allowed, but please be tidy.</:rule>
      </.house_rules>
  """
  attr :title, :string, default: "House Rules"
  slot :rule, required: true

  def house_rules(assigns) do
    ~H"""
    <section class="py-16 px-6">
      <div class="mx-auto max-w-[1000px] bg-base-200 rounded-3xl p-8 md:p-12 border border-base-300">
        <div class="flex flex-col md:flex-row gap-8 items-center justify-center">
          <div class="flex-1 md:flex-none w-full md:w-auto">
            <h3 class="text-2xl font-bold text-base-content mb-4">
              {@title}
            </h3>
            <ul class="space-y-3">
              <li
                :for={rule <- @rule}
                class="flex items-start gap-3 text-neutral"
              >
                <.icon
                  name="hero-check-circle"
                  class="w-5 h-5 text-secondary shrink-0 mt-0.5"
                />
                <span>{render_slot(rule)}</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>
    """
  end

  @doc """
  Renders a page header with title, description, booking button, carousel, and capacity info.

  ## Examples

      <.page_header
        title="Meeting Room"
        description="A private, sun-drenched sanctuary designed for focus and collaboration."
        booking_path={~p"/book/asset/\#{@asset.id}"}
        price="€40"
        price_unit="hour"
        capacity="Up to 8 People"
        images={@images}
      />
  """
  slot :title, required: true
  slot :description, required: true
  attr :booking_path, :string, required: true
  attr :booking_label, :string, default: "Book This Room"
  attr :price, :string, required: true
  attr :price_unit, :string, default: "hour"
  attr :capacity, :string, required: true
  attr :images, :list, default: []

  def page_header(assigns) do
    ~H"""
    <section class="relative pt-6 md:pt-10 pb-16 px-6 bg-base-100">
      <div class="mx-auto max-w-[1200px]">
        <.back_to_link
          navigate={~p"/"}
          value="Back to Home"
        />
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-16 items-center">
          <div class="order-2 lg:order-1 flex flex-col gap-6">
            <div>
              <h1 class="text-4xl md:text-5xl lg:text-6xl font-black text-base-content leading-[1.1] tracking-tight">
                {render_slot(@title)}
              </h1>
            </div>
            <p class="text-lg text-neutral leading-relaxed max-w-xl">
              {render_slot(@description)}
            </p>
            <div class="flex flex-col sm:flex-row gap-4 pt-2">
              <.link
                navigate={@booking_path}
                class="btn btn-primary h-14 px-8 rounded-2xl text-lg font-bold shadow-xl w-full sm:w-auto hover:-translate-y-1"
              >
                <span>{@booking_label}</span>
                <.icon name="hero-arrow-right" class="w-5 h-5" />
              </.link>
              <div class="flex items-center gap-2 text-neutral px-4 h-14 w-full sm:w-auto justify-center">
                <span class="text-2xl font-bold text-base-content">{@price}</span>
                <span class="text-sm">/ {@price_unit}</span>
              </div>
            </div>
          </div>
          <div class="order-1 lg:order-2 relative group">
            <div class="absolute -inset-1 bg-gradient-to-r from-primary to-secondary rounded-3xl blur opacity-25 group-hover:opacity-50 transition duration-1000 group-hover:duration-200">
            </div>
            <div class="relative overflow-hidden rounded-2xl aspect-[4/3] shadow-2xl">
              <.live_component
                module={SpazioSolazzoWeb.CarouselLiveComponent}
                id="page-header-carousel"
                images={@images}
                height="100%"
              />
              <div class="absolute inset-0 bg-gradient-to-t from-base-300/80 via-transparent to-transparent pointer-events-none">
              </div>
              <div class="absolute bottom-6 left-6 right-6 flex justify-between items-end pointer-events-none">
                <div>
                  <span class="block text-white font-bold text-sm mb-1 tracking-wide">
                    CAPACITY
                  </span>
                  <span class="text-white font-bold text-xl flex items-center gap-2">
                    <.icon name="hero-user-group" class="w-6 h-6" />
                    {@capacity}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  @doc """
  Renders an amenities/features section with a grid of feature cards.

  ## Examples

      <.features_section title="Everything you need" description="Top-tier amenities...">
        <:feature icon="tv" title="4K Presentation" description="..." color="sky" />
        <:feature icon="video-camera" title="Video Conferencing" description="..." color="orange" />
      </.features_section>
  """
  attr :title, :string, required: true
  attr :description, :string, required: true

  slot :feature, required: true do
    attr :icon, :string, required: true
    attr :title, :string, required: true
    attr :description, :string, required: true
    attr :color, :string
  end

  def features_section(assigns) do
    ~H"""
    <section class="py-20 bg-base-200 border-y border-base-300">
      <div class="mx-auto max-w-[1200px] px-6">
        <div class="text-center max-w-2xl mx-auto mb-16">
          <h2 class="text-3xl font-bold text-base-content mb-4">
            {@title}
          </h2>
          <p class="text-neutral">
            {@description}
          </p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <.feature_card
            :for={feature <- @feature}
            icon={feature.icon}
            title={feature.title}
            description={feature.description}
            color={Map.get(feature, :color, "primary")}
          />
        </div>
      </div>
    </section>
    """
  end
end
