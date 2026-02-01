defmodule SpazioSolazzo.BookingSystem do
  @moduledoc """
  Manages bookings, spaces, and time slots for the booking system.
  """

  use Ash.Domain,
    otp_app: :spazio_solazzo

  require Ash.Query
  alias SpazioSolazzo.BookingSystem.Space

  resources do
    resource SpazioSolazzo.BookingSystem.Space do
      define :get_space_by_slug, action: :read, get_by: [:slug]

      define :create_space,
        action: :create,
        args: [:name, :slug, :description, :public_capacity, :real_capacity]
    end

    resource SpazioSolazzo.BookingSystem.TimeSlotTemplate do
      define :get_space_time_slots_by_date,
        action: :get_space_time_slots_by_date,
        args: [:space_id, :date]

      define :create_time_slot_template,
        action: :create,
        args: [:start_time, :end_time, :day_of_week, :space_id]
    end

    resource SpazioSolazzo.BookingSystem.Booking do
      define :list_accepted_space_bookings_by_date,
        action: :list_accepted_space_bookings_by_date,
        args: [:space_id, :date]

      define :list_booking_requests,
        action: :list_booking_requests,
        args: [:space_id, :email, :date]

      define :create_booking,
        action: :create,
        args: [
          :space_id,
          :user_id,
          :date,
          :start_time,
          :end_time,
          :customer_name,
          :customer_email,
          :customer_phone,
          :customer_comment
        ]

      define :approve_booking, action: :approve, args: []
      define :reject_booking, action: :reject, args: [:reason]
      define :cancel_booking, action: :cancel, args: [:reason]
      define :delete_booking, action: :destroy, args: []
    end
  end

  def request_booking(space_id, user_id, date, start_time, end_time, customer_details) do
    create_booking(
      space_id,
      user_id,
      date,
      start_time,
      end_time,
      customer_details.name,
      customer_details.email,
      customer_details[:phone],
      customer_details[:comment]
    )
  end

  def create_walk_in(space_id, customer_details, start_datetime, end_datetime) do
    date = DateTime.to_date(start_datetime)
    start_time = DateTime.to_time(start_datetime)
    end_time = DateTime.to_time(end_datetime)

    case create_booking(
           space_id,
           nil,
           date,
           start_time,
           end_time,
           customer_details.name,
           customer_details.email,
           customer_details[:phone],
           customer_details[:comment]
         ) do
      {:ok, booking} ->
        approve_booking!(booking)
        {:ok, booking}

      error ->
        error
    end
  end

  def check_availability(space_id, date, start_time, end_time) do
    with {:ok, space} <- Ash.get(Space, space_id),
         {:ok, bookings} <- list_accepted_space_bookings_by_date(space_id, date) do
      overlapping_bookings =
        Enum.filter(bookings, fn booking ->
          times_overlap?(
            booking.start_time,
            booking.end_time,
            start_time,
            end_time
          )
        end)

      current_count = length(overlapping_bookings)

      cond do
        current_count >= space.real_capacity ->
          {:ok, :over_real_capacity}

        current_count >= space.public_capacity ->
          {:ok, :over_public_capacity}

        true ->
          {:ok, :available}
      end
    end
  end

  def get_slot_booking_counts(space_id, date, start_time, end_time) do
    with {:ok, all_bookings} <- list_booking_requests(space_id, nil, date) do
      overlapping_bookings =
        Enum.filter(all_bookings, fn booking ->
          times_overlap?(
            booking.start_time,
            booking.end_time,
            start_time,
            end_time
          )
        end)

      pending_count =
        overlapping_bookings
        |> Enum.count(&(&1.state == :requested))

      approved_count =
        overlapping_bookings
        |> Enum.count(&(&1.state == :accepted))

      {:ok, %{pending: pending_count, approved: approved_count}}
    end
  end

  defp times_overlap?(start1, end1, start2, end2) do
    Time.compare(start1, end2) == :lt and Time.compare(start2, end1) == :lt
  end
end
