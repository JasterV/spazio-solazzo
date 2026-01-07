defmodule SpazioSolazzoWeb.BookingComponents.TimeSlotButton do
  @moduledoc """
  Renders time slot buttons in different sizes showing availability status.
  """

  use SpazioSolazzoWeb, :html

  alias SpazioSolazzo.CalendarExt

  attr :time_slot, :map, required: true
  attr :booked, :boolean, required: true
  attr :rest, :global

  def compact(assigns) do
    ~H"""
    <button
      disabled={@booked}
      class={
        [
          # Base Compact Classes
          "p-4 border-2 transition-all text-center rounded-2xl",
          # State Classes
          if(@booked,
            do:
              "border-gray-300 dark:border-gray-600 bg-gray-100 dark:bg-gray-700 cursor-not-allowed opacity-75",
            else:
              "border-teal-400 dark:border-teal-600 hover:border-teal-600 dark:hover:border-teal-500 hover:bg-teal-50 dark:hover:bg-teal-900/30 cursor-pointer"
          )
        ]
      }
      {@rest}
    >
      <p class={["font-semibold", text_color(@booked, :primary)]}>
        {CalendarExt.format_time_range(@time_slot)}
      </p>
      <p class={["text-xs mt-1", text_color(@booked, :secondary)]}>
        {if @booked, do: "Booked", else: "Available"}
      </p>
    </button>
    """
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
