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
        asset_type="Room"
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
  attr :asset_type, :string, required: true
  attr :id, :string, default: nil

  def space_card(assigns) do
    ~H"""
    <div
      id={@id}
      class="group relative overflow-hidden rounded-2xl bg-white dark:bg-slate-800 shadow-sm border border-slate-200 dark:border-slate-800 hover:border-sky-500/50 transition-all duration-300"
    >
      <div class={[
        "flex flex-col h-full",
        @image_position == :left && "md:flex-row",
        @image_position == :right && "md:flex-row-reverse"
      ]}>
        <div class="md:w-2/5 relative h-64 md:h-auto overflow-hidden">
          <div
            class="absolute inset-0 bg-cover bg-center transition-transform duration-700 group-hover:scale-105"
            style={"background-image: url('#{@image_url}');"}
          >
          </div>
          <div class="absolute inset-0 bg-gradient-to-t from-slate-900/60 to-transparent md:hidden">
          </div>
          <div class="absolute bottom-4 left-4 md:hidden">
            <span class={[
              "text-white text-xs font-bold px-2 py-1 rounded uppercase tracking-wider",
              @primary_label_variant == :primary && "bg-sky-500",
              @primary_label_variant == :secondary && "bg-slate-600",
              @primary_label_variant == :accent && "bg-yellow-400 text-slate-900"
            ]}>
              {@primary_label}
            </span>
          </div>
        </div>

        <div class="flex-1 p-6 md:p-8 flex flex-col justify-center">
          <div class="flex items-center justify-between mb-2">
            <span class={[
              "hidden md:inline-block text-xs font-bold px-2 py-1 rounded uppercase tracking-wider mb-2",
              @primary_label_variant == :primary &&
                "text-sky-500 bg-sky-100 dark:bg-sky-900/20",
              @primary_label_variant == :secondary &&
                "text-slate-600 dark:text-slate-400 bg-slate-100 dark:bg-slate-800",
              @primary_label_variant == :accent &&
                "text-yellow-700 dark:text-yellow-400 bg-yellow-100 dark:bg-yellow-900/20"
            ]}>
              {@primary_label}
            </span>
            <%= if @secondary_label do %>
              <div class="flex items-center gap-2 text-slate-500 dark:text-slate-400 text-sm">
                <%= if @secondary_label_icon do %>
                  <.icon name={@secondary_label_icon} class="size-[18px]" />
                <% end %>
                <span>{@secondary_label}</span>
              </div>
            <% end %>
          </div>
          <h3 class="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-3">
            {@title}
          </h3>
          <p class="text-slate-600 dark:text-slate-400 mb-6 leading-relaxed">
            {@description}
            <%= if @note do %>
              <span class={[
                "font-medium",
                @primary_label_variant == :accent &&
                  "text-yellow-600 dark:text-yellow-400",
                @primary_label_variant != :accent &&
                  "text-slate-700 dark:text-slate-300"
              ]}>
                {@note}
              </span>
            <% end %>
          </p>

          <div class="flex flex-col sm:flex-row gap-4 sm:items-center justify-between mt-auto pt-6 border-t border-slate-100 dark:border-slate-800">
            <div class="flex flex-col">
              <span class="text-sm text-slate-500">Starting from</span>
              <span class="text-lg font-bold text-slate-900 dark:text-slate-100">
                €{@price}
                <span class="text-sm font-normal text-slate-500">/ {@time_unit}</span>
              </span>
            </div>
            <.link
              navigate={@booking_url}
              class="h-10 px-6 bg-sky-500 hover:bg-sky-600 text-white rounded-lg font-medium transition-colors flex items-center justify-center gap-2 group-hover:shadow-lg group-hover:shadow-sky-500/20"
            >
              <.icon name="hero-calendar" class="size-5" />
              Book {@asset_type}
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
