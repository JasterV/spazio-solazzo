defmodule SpazioSolazzo.CalendarExt do
  @moduledoc """
  Extension module for Calendar with helper date and time formatting functions
  """

  def format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  def format_time_range(%{start_time: start_time, end_time: end_time}) do
    start_time = Calendar.strftime(start_time, "%I:%M %p")
    end_time = Calendar.strftime(end_time, "%I:%M %p")

    "#{start_time} - #{end_time}"
  end
end
