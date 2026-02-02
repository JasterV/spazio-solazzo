defmodule SpazioSolazzo.BookingSystem do
  @moduledoc """
  Manages bookings, spaces, and time slots for the booking system.
  """

  use Ash.Domain,
    otp_app: :spazio_solazzo

  resources do
    resource SpazioSolazzo.BookingSystem.Space do
      define :get_space_by_slug, action: :read, get_by: [:slug]

      define :create_space,
        action: :create,
        args: [:name, :slug, :description, :capacity]

      define :check_availability,
        action: :check_availability,
        args: [:space_id, :date, :start_time, :end_time]
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

      define :count_pending_requests, action: :count_pending_requests

      define :get_slot_booking_counts,
        action: :get_slot_booking_counts,
        args: [:space_id, :date, :start_time, :end_time]

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

      define :create_walk_in,
        action: :create_walk_in,
        args: [
          :space_id,
          :start_datetime,
          :end_datetime,
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
end
