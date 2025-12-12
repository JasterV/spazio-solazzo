defmodule SpazioSolazzoWeb.BookingComponents.TimeSlotButton do
  use Phoenix.Component

  attr :time_slot, :map, required: true
  attr :booked, :boolean, required: true
  attr :variant, :atom, values: [:compact, :large, :xlarge], default: :large
  attr :rest, :global

  def render(assigns) do
    ~H"""
    <button
      disabled={@booked}
      class={button_classes(@variant, @booked)}
      {@rest}
    >
      <%= if @variant == :compact do %>
        {compact_content(assigns)}
      <% else %>
        {large_content(assigns)}
      <% end %>
    </button>
    """
  end

  defp compact_content(assigns) do
    ~H"""
    <p class={["font-semibold", text_color(@booked, :primary)]}>
      {Calendar.strftime(@time_slot.start_time, "%I:%M %p")}
    </p>
    <p class={["text-xs mt-1", text_color(@booked, :secondary)]}>
      {if @booked, do: "Booked", else: "Available"}
    </p>
    """
  end

  defp large_content(assigns) do
    ~H"""
    <div class="flex justify-between items-center">
      <div>
        <p class={[
          @variant == :xlarge && "font-bold text-lg",
          @variant == :large && "font-semibold",
          text_color(@booked, :primary)
        ]}>
          {@time_slot.name}
        </p>
        <p class={[
          @variant == :xlarge && "mt-1",
          @variant == :large && "text-sm",
          "text-gray-600 dark:text-gray-300"
        ]}>
          {Calendar.strftime(@time_slot.start_time, "%I:%M %p")} - {Calendar.strftime(
            @time_slot.end_time,
            "%I:%M %p"
          )}
        </p>
      </div>

      <%= if @booked do %>
        <div class={[
          @variant == :large && "px-3 py-1",
          @variant == :xlarge && "px-4 py-2",
          "bg-gray-200 dark:bg-gray-600 text-gray-700 dark:text-gray-300 text-sm font-semibold rounded-full"
        ]}>
          Booked
        </div>
      <% end %>

      <%= if !@booked do %>
        <div class={[
          @variant == :large && "px-3 py-1",
          @variant == :xlarge && "px-4 py-2",
          "bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 text-sm font-semibold rounded-full"
        ]}>
          Available
        </div>
      <% end %>
    </div>
    """
  end

  defp button_classes(variant, booked) do
    base_classes =
      case variant do
        :compact -> "p-4 border-2 transition-all text-center rounded-lg"
        :large -> "w-full p-4 border transition-all text-left rounded-lg"
        :xlarge -> "w-full p-6 border-2 transition-all text-left rounded-lg"
      end

    state_classes =
      if booked do
        "bg-gray-100 dark:bg-gray-700 border-gray-300 dark:border-gray-600 cursor-not-allowed opacity-75"
      else
        case variant do
          :large ->
            "border-gray-200 dark:bg-gray-800 dark:border-gray-700 hover:border-indigo-600 dark:hover:border-indigo-500 hover:bg-indigo-50 dark:hover:bg-indigo-900/30 cursor-pointer"

          v when v in [:compact, :xlarge] ->
            "border-gray-200 dark:border-gray-600 hover:border-indigo-600 dark:hover:border-indigo-500 hover:bg-indigo-50 dark:hover:bg-indigo-900/30 cursor-pointer"
        end
      end

    [base_classes, state_classes]
  end

  defp text_color(booked, type) do
    if booked do
      "text-gray-500 dark:text-gray-400"
    else
      case type do
        :primary -> "text-gray-900 dark:text-white"
        :secondary -> "text-gray-600 dark:text-gray-300"
      end
    end
  end
end
