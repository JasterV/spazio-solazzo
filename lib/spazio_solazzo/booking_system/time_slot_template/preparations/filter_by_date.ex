defmodule SpazioSolazzo.BookingSystem.TimeSlotTemplate.Preparations.FilterByDate do
  @moduledoc """
  Filters time slot templates by matching the day of the week from a given date.
  """

  use Ash.Resource.Preparation

  @impl true
  def prepare(query, _opts, _context) do
    case Ash.Query.get_argument(query, :date) do
      nil ->
        query

      date ->
        day_of_week = parse_date_to_week_day(date)
        Ash.Query.filter(query, day_of_week == ^day_of_week)
    end
  end

  defp parse_date_to_week_day(date) do
    case Date.day_of_week(date) do
      1 -> :monday
      2 -> :tuesday
      3 -> :wednesday
      4 -> :thursday
      5 -> :friday
      6 -> :saturday
      7 -> :sunday
    end
  end
end
