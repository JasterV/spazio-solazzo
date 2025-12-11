defmodule SpazioSolazzo.BookingSystem.TimeSlotTemplate.Changes.PreventCreationOverlap do
  @moduledoc false

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Ash.Resource.Change

  require Ash.Query

  alias SpazioSolazzo.BookingSystem.TimeSlotTemplate

  @impl true
  @spec change(Changeset.t(), keyword, Change.context()) :: Changeset.t()
  def change(changeset, _opts, _context) do
    space_id = Ash.Changeset.get_attribute(changeset, :space_id)
    start_time = Ash.Changeset.get_attribute(changeset, :start_time)
    end_time = Ash.Changeset.get_attribute(changeset, :end_time)
    day_of_week = Ash.Changeset.get_attribute(changeset, :day_of_week)

    overlapping =
      TimeSlotTemplate
      |> Ash.Query.filter(space_id == ^space_id)
      |> Ash.Query.filter(day_of_week == ^day_of_week)
      |> Ash.Query.filter(start_time < ^end_time and end_time > ^start_time)
      |> Ash.read()

    case overlapping do
      {:ok, []} ->
        changeset

      {:ok, _} ->
        Changeset.add_error(changeset,
          field: :base,
          message: "time slot overlaps with existing template for this space and day"
        )

      {:error, err} ->
        Changeset.add_error(changeset,
          field: :base,
          message: "failed to validate overlap: #{inspect(err)}"
        )
    end
  end
end
