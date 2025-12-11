defmodule SpazioSolazzo.BookingSystem do
  use Ash.Domain,
    otp_app: :spazio_solazzo

  resources do
    resource SpazioSolazzo.BookingSystem.Space
    resource SpazioSolazzo.BookingSystem.Asset
    resource SpazioSolazzo.BookingSystem.TimeSlotTemplate
    resource SpazioSolazzo.BookingSystem.Booking
  end
end
