defmodule SpazioSolazzo.BookingSystem.BookingPaginationTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  describe "read_pending_bookings/3 pagination" do
    setup do
      {:ok, space} =
        BookingSystem.create_space(
          "Coworking",
          "coworking-pagination-test",
          "Test space for pagination",
          10
        )

      base_date = Date.add(Date.utc_today(), 1)

      pending_bookings =
        for i <- 1..15 do
          {:ok, booking} =
            BookingSystem.create_booking(
              space.id,
              nil,
              base_date,
              ~T[09:00:00],
              ~T[10:00:00],
              "Customer #{i}",
              "customer#{i}@example.com",
              nil,
              nil
            )

          booking
        end

      %{space: space, pending_bookings: pending_bookings, tomorrow: base_date}
    end

    test "returns first page with default limit of 10" do
      {:ok, page} =
        BookingSystem.read_pending_bookings(
          nil,
          nil,
          nil,
          page: [limit: 10, offset: 0, count: true]
        )

      assert length(page.results) == 10
      assert page.count == 15
      assert page.limit == 10
      assert page.offset == 0
      assert page.more? == true
    end

    test "returns second page correctly" do
      {:ok, page} =
        BookingSystem.read_pending_bookings(
          nil,
          nil,
          nil,
          page: [limit: 10, offset: 10, count: true]
        )

      assert length(page.results) == 5
      assert page.count == 15
      assert page.more? == false
    end

    test "filters by space_id", %{space: space} do
      {:ok, other_space} =
        BookingSystem.create_space(
          "Other Space",
          "other-space-pagination",
          "Another test space",
          5
        )

      tomorrow = Date.add(Date.utc_today(), 1)

      {:ok, _} =
        BookingSystem.create_booking(
          other_space.id,
          nil,
          tomorrow,
          ~T[10:00:00],
          ~T[11:00:00],
          "Other Customer",
          "other@example.com",
          nil,
          nil
        )

      {:ok, page} =
        BookingSystem.read_pending_bookings(
          space.id,
          nil,
          nil,
          page: [limit: 10, offset: 0, count: true]
        )

      assert page.count == 15
      assert Enum.all?(page.results, fn b -> b.space_id == space.id end)
    end

    test "filters by email" do
      {:ok, page} =
        BookingSystem.read_pending_bookings(
          nil,
          "customer1@example.com",
          nil,
          page: [limit: 10, offset: 0, count: true]
        )

      assert page.count == 1
      assert hd(page.results).customer_email == "customer1@example.com"
    end

    test "filters by date", %{tomorrow: tomorrow} do
      {:ok, page} =
        BookingSystem.read_pending_bookings(
          nil,
          nil,
          tomorrow,
          page: [limit: 20, offset: 0, count: true]
        )

      assert page.count == 15
      assert Enum.all?(page.results, fn b -> DateTime.to_date(b.start_datetime) == tomorrow end)
    end

    test "sorts by inserted_at descending (newest first)" do
      {:ok, page} =
        BookingSystem.read_pending_bookings(
          nil,
          nil,
          nil,
          page: [limit: 2, offset: 0, count: true]
        )

      [first, second] = page.results
      assert DateTime.compare(first.inserted_at, second.inserted_at) in [:gt, :eq]
    end

    test "returns empty results when no bookings match" do
      {:ok, page} =
        BookingSystem.read_pending_bookings(
          nil,
          "nonexistent@example.com",
          nil,
          page: [limit: 10, offset: 0, count: true]
        )

      assert page.results == []
      assert page.count == 0
      assert page.more? == false
    end

    test "only returns requested state bookings", %{pending_bookings: bookings} do
      [first_booking | _] = bookings

      {:ok, _} = BookingSystem.approve_booking(first_booking)

      {:ok, page} =
        BookingSystem.read_pending_bookings(
          nil,
          nil,
          nil,
          page: [limit: 20, offset: 0, count: true],
          load: [:space]
        )

      assert page.count == 14
      assert Enum.all?(page.results, fn b -> b.state == :requested end)
    end

    test "combined filters work together", %{space: space, tomorrow: tomorrow} do
      {:ok, page} =
        BookingSystem.read_pending_bookings(
          space.id,
          "customer5@example.com",
          tomorrow,
          page: [limit: 10, offset: 0, count: true]
        )

      assert page.count == 1
      result = hd(page.results)
      assert result.space_id == space.id
      assert result.customer_email == "customer5@example.com"
      assert DateTime.to_date(result.start_datetime) == tomorrow
    end
  end

  describe "read_booking_history/3 pagination" do
    setup do
      {:ok, space} =
        BookingSystem.create_space(
          "Coworking History",
          "coworking-history-test",
          "Test space for history pagination",
          10
        )

      base_date = Date.add(Date.utc_today(), 1)

      for i <- 1..30 do
        {:ok, booking} =
          BookingSystem.create_booking(
            space.id,
            nil,
            base_date,
            ~T[09:00:00],
            ~T[10:00:00],
            "Customer #{i}",
            "customer#{i}@example.com",
            nil,
            nil
          )

        cond do
          rem(i, 10) == 0 ->
            BookingSystem.reject_booking(booking, "Test rejection")

          rem(i, 5) == 0 ->
            {:ok, approved} = BookingSystem.approve_booking(booking)
            BookingSystem.cancel_booking(approved, "Test cancellation")

          true ->
            BookingSystem.approve_booking(booking)
        end
      end

      %{space: space, tomorrow: base_date}
    end

    test "returns first page with default limit of 25" do
      {:ok, page} =
        BookingSystem.read_booking_history(
          nil,
          nil,
          nil,
          page: [limit: 25, offset: 0, count: true]
        )

      assert length(page.results) == 25
      assert page.count == 30
      assert page.more? == true
    end

    test "returns second page correctly" do
      {:ok, page} =
        BookingSystem.read_booking_history(
          nil,
          nil,
          nil,
          page: [limit: 25, offset: 25, count: true]
        )

      assert length(page.results) == 5
      assert page.count == 30
      assert page.more? == false
    end

    test "returns only accepted, rejected, and cancelled bookings", %{space: space} do
      tomorrow = Date.add(Date.utc_today(), 2)

      {:ok, _pending} =
        BookingSystem.create_booking(
          space.id,
          nil,
          tomorrow,
          ~T[10:00:00],
          ~T[11:00:00],
          "Pending Customer",
          "pending@example.com",
          nil,
          nil
        )

      {:ok, page} =
        BookingSystem.read_booking_history(
          nil,
          nil,
          nil,
          page: [limit: 50, offset: 0, count: true]
        )

      assert page.count == 30
      assert Enum.all?(page.results, fn b -> b.state in [:accepted, :rejected, :cancelled] end)
    end

    test "sorts by start_datetime descending (most recent first)" do
      {:ok, page} =
        BookingSystem.read_booking_history(
          nil,
          nil,
          nil,
          page: [limit: 2, offset: 0, count: true]
        )

      [first, second] = page.results
      assert DateTime.compare(first.start_datetime, second.start_datetime) in [:gt, :eq]
    end

    test "filters by space_id", %{space: space} do
      {:ok, other_space} =
        BookingSystem.create_space(
          "Other History Space",
          "other-history-space",
          "Another test space",
          5
        )

      tomorrow = Date.add(Date.utc_today(), 1)

      {:ok, other_booking} =
        BookingSystem.create_booking(
          other_space.id,
          nil,
          tomorrow,
          ~T[10:00:00],
          ~T[11:00:00],
          "Other Customer",
          "other@example.com",
          nil,
          nil
        )

      BookingSystem.approve_booking(other_booking)

      {:ok, page} =
        BookingSystem.read_booking_history(
          space.id,
          nil,
          nil,
          page: [limit: 50, offset: 0, count: true]
        )

      assert page.count == 30
      assert Enum.all?(page.results, fn b -> b.space_id == space.id end)
    end

    test "filters by email" do
      {:ok, page} =
        BookingSystem.read_booking_history(
          nil,
          "customer1@example.com",
          nil,
          page: [limit: 10, offset: 0, count: true]
        )

      assert page.count == 1
      assert hd(page.results).customer_email == "customer1@example.com"
    end

    test "filters by date", %{tomorrow: tomorrow} do
      {:ok, page} =
        BookingSystem.read_booking_history(
          nil,
          nil,
          tomorrow,
          page: [limit: 50, offset: 0, count: true]
        )

      assert page.count == 30
      assert Enum.all?(page.results, fn b -> DateTime.to_date(b.start_datetime) == tomorrow end)
    end

    test "combined filters work together", %{space: space, tomorrow: tomorrow} do
      {:ok, page} =
        BookingSystem.read_booking_history(
          space.id,
          "customer2@example.com",
          tomorrow,
          page: [limit: 10, offset: 0, count: true]
        )

      assert page.count == 1
      result = hd(page.results)
      assert result.space_id == space.id
      assert result.customer_email == "customer2@example.com"
      assert DateTime.to_date(result.start_datetime) == tomorrow
    end

    test "returns empty results when no bookings match" do
      {:ok, page} =
        BookingSystem.read_booking_history(
          nil,
          "nonexistent@example.com",
          nil,
          page: [limit: 25, offset: 0, count: true]
        )

      assert page.results == []
      assert page.count == 0
      assert page.more? == false
    end
  end
end
