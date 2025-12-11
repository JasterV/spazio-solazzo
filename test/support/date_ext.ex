defmodule SpazioSolazzo.DateExt do
  @moduledoc """
  Provides date utility functions for converting between formats.
  """

  def day_of_week_atom(date) do
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
