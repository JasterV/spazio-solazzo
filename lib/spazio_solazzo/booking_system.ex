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
      define :admin_search_bookings,
        action: :admin_dashboard_search,
        args: [:space_id, :email, :date]

      define :search_bookings,
        action: :search,
        args: [:space_id, :start_datetime, :end_datetime, :states, :select]

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
