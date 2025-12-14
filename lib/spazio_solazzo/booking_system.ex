defmodule SpazioSolazzo.BookingSystem do
  use Ash.Domain,
    otp_app: :spazio_solazzo,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource SpazioSolazzo.BookingSystem.Space
    resource SpazioSolazzo.BookingSystem.Asset
    resource SpazioSolazzo.BookingSystem.TimeSlotTemplate
    resource SpazioSolazzo.BookingSystem.Booking

    resource SpazioSolazzo.BookingSystem.EmailVerification do
      define :create_verification_code, action: :create, args: [:email]
      define :verify_code, action: :verify, args: [:code]
      define :expire_verification_code, action: :expire, args: []
    end
  end
end
