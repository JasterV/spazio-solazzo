defmodule SpazioSolazzoWeb.AdminDashboardComponents do
  @moduledoc """
  Reusable components for the booking flow.
  """
  use Phoenix.Component

  import SpazioSolazzoWeb.CoreComponents, only: [icon: 1]

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :color, :atom, values: [:primary, :secondary], required: true
  attr :icon, :string, required: true
  attr :navigate, :string, required: true

  @doc """
  Renders a tool card to be displayed in the admin dashboard
  """
  def tool_card(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={"group bg-white dark:bg-slate-800 rounded-3xl p-8 border-2 border-slate-200 dark:border-slate-700 shadow-xl shadow-slate-200/50 dark:shadow-none #{container_color_class(@color)} transition-all duration-300 hover:scale-[1.02]"}
    >
      <div class="flex flex-col h-full">
        <div class="flex items-start justify-between mb-6">
          <div class={"size-16 rounded-2xl #{icon_color_class(@color)} flex items-center justify-center group-hover:scale-110 transition-transform duration-300"}>
            <.icon name={@icon} class="w-8 h-8" />
          </div>
        </div>

        <h2 class={"text-2xl font-bold text-slate-900 dark:text-white mb-3 #{title_color_class(@color)} transition-colors"}>
          {@title}
        </h2>

        <p class="text-slate-600 dark:text-slate-400 mb-6 flex-grow">
          {@description}
        </p>

        <div class={"flex items-center #{tooltip_color_class(@color)} font-semibold group-hover:gap-3 transition-all"}>
          <span>Open Tool</span>
          <.icon
            name="hero-arrow-right"
            class="w-5 h-5 group-hover:translate-x-1 transition-transform"
          />
        </div>
      </div>
    </.link>
    """
  end

  defp container_color_class(:primary), do: "hover:border-primary dark:hover:border-primary"
  defp container_color_class(:secondary), do: "hover:border-sky-500 dark:hover:border-sky-400"

  defp icon_color_class(:primary),
    do: "bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400"

  defp icon_color_class(:secondary),
    do: "bg-sky-100 dark:bg-sky-900/30 text-sky-600 dark:text-sky-400 "

  defp title_color_class(:primary), do: "group-hover:text-primary dark:group-hover:text-primary"
  defp title_color_class(:secondary), do: "group-hover:text-sky-500 dark:group-hover:text-sky-400"

  defp tooltip_color_class(:primary), do: "text-primary dark:text-primary-hover"
  defp tooltip_color_class(:secondary), do: "text-sky-500 dark:text-sky-400"
end
