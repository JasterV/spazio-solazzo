defmodule SpazioSolazzo.BookingSystem do
  use Ash.Domain,
    otp_app: :spazio_solazzo

  resources do
    resource SpazioSolazzo.BookingSystem.Space do
      define :get_space_by_slug, action: :read, get_by: [:slug]
    end

    resource SpazioSolazzo.BookingSystem.Asset do
      define :get_asset_by_space_id, action: :read, get_by: [:space_id]
      define :get_space_assets, action: :get_space_assets, args: [:space_id]
    end

    resource SpazioSolazzo.BookingSystem.TimeSlotTemplate do
      define :get_space_time_slots_by_date,
        action: :get_space_time_slots_by_date,
        args: [:space_id, :date]
    end

    resource SpazioSolazzo.BookingSystem.Booking do
      define :list_asset_bookings_by_date,
        action: :list_asset_bookings_by_date,
        args: [:asset_id, :date]

      define :create_booking,
        action: :create,
        args: [
          :time_slot_template_id,
          :asset_id,
          :date,
          :customer_name,
          :customer_email
        ]
    end

    resource SpazioSolazzo.BookingSystem.EmailVerification do
      define :create_verification_code, action: :create, args: [:email]
      define :verify_code, action: :verify, args: [:code]
      define :expire_verification_code, action: :expire, args: []
    end
  end
end
