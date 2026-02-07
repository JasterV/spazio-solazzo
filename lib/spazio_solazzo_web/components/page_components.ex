defmodule SpazioSolazzoWeb.PageComponents do
  @moduledoc """
  Provides UI components specific to the page live view.
  """
  use Phoenix.Component

  import SpazioSolazzoWeb.CoreComponents

  @doc """
  Renders a space card component for displaying booking spaces.

  ## Examples

      <.space_card
        title="Coworking"
        description="Flexible desk spaces for remote work"
        price="15"
        time_unit="4 hours"
        image_url="https://..."
        primary_label="Workspace"
        image_position={:left}
        booking_url="/coworking"
        asset_type="Desk"
      />

      <.space_card
        title="Meeting Room"
        description="Private conference rooms"
        price="40"
        time_unit="hour"
        image_url="https://..."
        primary_label="Business"
        primary_label_variant={:secondary}
        secondary_label="Up to 8 people"
        secondary_label_icon="hero-user-group"
        image_position={:right}
        booking_url="/meeting"
      />
  """
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :price, :string, required: true
  attr :time_unit, :string, required: true
  attr :image_url, :string, required: true
  attr :primary_label, :string, required: true
  attr :primary_label_variant, :atom, default: :primary, values: [:primary, :secondary, :accent]
  attr :secondary_label, :string, default: nil
  attr :secondary_label_icon, :string, default: nil
  attr :note, :string, default: nil
  attr :image_position, :atom, default: :left, values: [:left, :right]
  attr :booking_url, :string, required: true
  attr :id, :string, default: nil

  def space_card(assigns) do
    ~H"""
    <div
      id={@id}
      class="card group relative overflow-hidden rounded-3xl bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-500"
    >
      <div class={[
        "flex flex-col h-full",
        @image_position == :left && "md:flex-row",
        @image_position == :right && "md:flex-row-reverse"
      ]}>
        <div class="md:w-1/2 relative h-80 md:h-auto overflow-hidden">
          <div
            class="absolute inset-0 bg-cover bg-center transition-transform duration-700 group-hover:scale-105"
            style={"background-image: url('#{@image_url}');"}
          >
          </div>
        </div>

        <div class="card-body flex-1 p-10 md:p-16 flex flex-col justify-center">
          <div class="flex items-center justify-between mb-6">
            <span class={[
              "badge badge-outline font-bold uppercase tracking-[0.2em]",
              @primary_label_variant == :primary && "badge-primary",
              @primary_label_variant == :secondary && "badge-secondary",
              @primary_label_variant == :accent && "badge-accent"
            ]}>
              {@primary_label}
            </span>
            <%= if @secondary_label do %>
              <div class="flex items-center gap-2 text-sm font-medium text-neutral">
                <%= if @secondary_label_icon do %>
                  <.icon name={@secondary_label_icon} class="size-5 text-primary" />
                <% end %>
                <span>{@secondary_label}</span>
              </div>
            <% end %>
          </div>
          <h3 class="card-title text-3xl font-extrabold mb-4 text-base-content">
            {@title}
          </h3>
          <p class="mb-10 leading-relaxed text-lg font-light text-neutral">
            {@description}
            <%= if @note do %>
              <span class="font-medium text-neutral">
                {@note}
              </span>
            <% end %>
          </p>

          <div class="card-actions flex flex-col sm:flex-row gap-8 sm:items-center justify-between mt-auto pt-10 border-t border-base-200">
            <span class="text-3xl font-extrabold text-base-content">
              €{@price}
              <span class="text-base font-light text-neutral">/ {@time_unit}</span>
            </span>
            <.link
              navigate={@booking_url}
              class="btn btn-primary h-10 px-5 rounded-2xl uppercase text-xs tracking-widest"
            >
              View more <.icon name="hero-arrow-right" class="size-5" />
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
