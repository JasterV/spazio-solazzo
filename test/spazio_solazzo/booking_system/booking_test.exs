defmodule SpazioSolazzo.BookingSystem.BookingTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Booking

  alias SpazioSolazzo.BookingSystem.Booking.EmailWorker

  setup do
    {:ok, space} = BookingSystem.create_space("Test", "test2", "desc")
    {:ok, asset} = BookingSystem.create_asset("Table 1", space.id)

    {:ok, time_slot} =
      BookingSystem.create_time_slot_template(
        "Full Day",
        ~T[09:00:00],
        ~T[18:00:00],
        :monday,
        space.id
      )

    %{space: space, asset: asset, time_slot: time_slot}
  end

  test "it can create a booking from a time slot template", %{asset: asset, time_slot: time_slot} do
    {:ok, booking} =
      BookingSystem.create_booking(
        time_slot.id,
        asset.id,
        Date.utc_today(),
        "John",
        "john@example.com"
      )

    assert booking.start_time == time_slot.start_time
    assert booking.end_time == time_slot.end_time
    assert booking.state == :reserved
  end

  test "it sends a confirmation email after the booking is created", %{
    asset: asset,
    time_slot: time_slot
  } do
    {:ok, booking} =
      BookingSystem.create_booking(
        time_slot.id,
        asset.id,
        Date.utc_today(),
        "John",
        "john@example.com"
      )

    formatted_date = Calendar.strftime(booking.date, "%A, %B %d")

    assert_enqueued worker: EmailWorker,
                    args: %{
                      "booking_id" => booking.id,
                      "customer_name" => booking.customer_name,
                      "customer_email" => booking.customer_email,
                      "date" => formatted_date,
                      "start_time" => booking.start_time,
                      "end_time" => booking.end_time
                    }
  end

  test "it can confirm a booking was paid", %{asset: asset, time_slot: time_slot} do
    {:ok, booking} =
      BookingSystem.create_booking(
        time_slot.id,
        asset.id,
        Date.utc_today(),
        "John",
        "john@example.com"
      )

    assert booking.state == :reserved

    assert {:ok, booking} = BookingSystem.confirm_booking(booking)

    assert booking.state == :completed
  end

  test "it can cancel a booking", %{asset: asset, time_slot: time_slot} do
    {:ok, booking} =
      BookingSystem.create_booking(
        time_slot.id,
        asset.id,
        Date.utc_today(),
        "John",
        "john@example.com"
      )

    assert booking.state == :reserved

    assert {:ok, booking} = BookingSystem.cancel_booking(booking)

    assert booking.state == :cancelled
  end

  test "it can list asset bookings by date", %{asset: asset, space: space, time_slot: time_slot} do
    {:ok, asset2} = BookingSystem.create_asset("Table 2", space.id)
    {:ok, asset3} = BookingSystem.create_asset("Table 3", space.id)
    today_date = Date.utc_today()

    {:ok, time_slot2} =
      BookingSystem.create_time_slot_template(
        "Tuesday afternoon",
        ~T[13:00:00],
        ~T[18:00:00],
        :tuesday,
        space.id
      )

    {:ok, time_slot3} =
      BookingSystem.create_time_slot_template(
        "Tuesday morning",
        ~T[09:00:00],
        ~T[13:00:00],
        :tuesday,
        space.id
      )

    # Create the bookings we want to query
    assert {:ok, _} =
             BookingSystem.create_booking(
               time_slot2.id,
               asset.id,
               today_date,
               "John",
               "john@example.com"
             )

    assert {:ok, _} =
             BookingSystem.create_booking(
               time_slot3.id,
               asset.id,
               today_date,
               "John",
               "john@example.com"
             )

    # Create bookings for asset but another date
    assert {:ok, _} =
             BookingSystem.create_booking(
               time_slot2.id,
               asset.id,
               Date.add(today_date, 1),
               "John",
               "john@example.com"
             )

    # Create bookings for other assets
    assert {:ok, _} =
             BookingSystem.create_booking(
               time_slot.id,
               asset2.id,
               today_date,
               "John",
               "john@example.com"
             )

    assert {:ok, _} =
             BookingSystem.create_booking(
               time_slot.id,
               asset3.id,
               today_date,
               "John",
               "john@example.com"
             )

    assert {:ok, bookings} = BookingSystem.list_asset_bookings_by_date(asset.id, Date.utc_today())

    asset_id = asset.id

    assert [
             %Booking{date: ^today_date, asset_id: ^asset_id},
             %Booking{date: ^today_date, asset_id: ^asset_id}
           ] = bookings
  end
end
