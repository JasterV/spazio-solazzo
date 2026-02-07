defmodule SpazioSolazzo.BookingSystem.TimeSlotTemplate.Calculations.SlotBookingStats do
  @moduledoc """
  Calculates booking statistics for time slots by fetching all bookings for the day once,
  then filtering in memory. This eliminates N+1 query problems.
  """

  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context) do
    [:start_time, :end_time, :space_id]
  end

  @impl true
  def calculate(records, _opts, %{arguments: arguments}) do
    date = Map.get(arguments, :date)
    space_id = Map.get(arguments, :space_id)
    capacity = Map.get(arguments, :capacity)
    user_id = Map.get(arguments, :user_id)

    # Fetch all bookings for the entire day ONCE
    day_start = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
    day_end = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")

    {:ok, all_bookings} =
      SpazioSolazzo.BookingSystem.search_bookings(
        space_id,
        day_start,
        day_end,
        [:requested, :accepted],
        [:start_datetime, :end_datetime, :state, :user_id]
      )

    # Calculate stats for each slot using the cached bookings
    Enum.map(records, fn slot ->
      slot_start = DateTime.new!(date, slot.start_time, "Etc/UTC")
      slot_end = DateTime.new!(date, slot.end_time, "Etc/UTC")

      # Filter bookings that overlap with this slot
      overlapping =
        Enum.filter(all_bookings, fn booking ->
          DateTime.compare(booking.start_datetime, slot_end) == :lt and
            DateTime.compare(booking.end_datetime, slot_start) == :gt
        end)

      requested_count = Enum.count(overlapping, &(&1.state == :requested))
      accepted_count = Enum.count(overlapping, &(&1.state == :accepted))

      user_has_booking =
        if user_id do
          Enum.any?(overlapping, &(&1.user_id == user_id))
        else
          false
        end

      availability = if accepted_count >= capacity, do: :over_capacity, else: :available

      %{
        requested_count: requested_count,
        accepted_count: accepted_count,
        user_has_booking: user_has_booking,
        availability_status: availability
      }
    end)
  end
end
