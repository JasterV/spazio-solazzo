defmodule SpazioSolazzo.BookingSystem.SpaceTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  describe "create_space/5" do
    test "creates a space with all attributes" do
      assert {:ok, space} =
               BookingSystem.create_space(
                 "Test Space",
                 "test-space",
                 "test description",
                 10,
                 12
               )

      assert space.name == "Test Space"
      assert space.slug == "test-space"
      assert space.description == "test description"
      assert space.public_capacity == 10
      assert space.real_capacity == 12
    end

    test "requires public_capacity to be less than or equal to real_capacity" do
      assert {:error, error} =
               BookingSystem.create_space(
                 "Invalid Space",
                 "invalid",
                 "description",
                 15,
                 10
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be less than or equal to real_capacity")
    end

    test "allows public_capacity to equal real_capacity" do
      assert {:ok, space} =
               BookingSystem.create_space(
                 "Equal Space",
                 "equal",
                 "description",
                 10,
                 10
               )

      assert space.public_capacity == 10
      assert space.real_capacity == 10
    end

    test "requires positive capacity values" do
      assert {:error, error} =
               BookingSystem.create_space(
                 "Zero Space",
                 "zero",
                 "description",
                 -1,
                 5
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be greater than 0")
    end
  end

  describe "get_space_by_slug/1" do
    test "retrieves space by slug" do
      {:ok, _} =
        BookingSystem.create_space("Space", "test-slug", "test description", 5, 5)

      assert {:ok, space} = BookingSystem.get_space_by_slug("test-slug")

      assert space.slug == "test-slug"
      assert space.name == "Space"
    end

    test "returns error when space not found" do
      assert {:error, _} = BookingSystem.get_space_by_slug("nonexistent")
    end
  end

  describe "space uniqueness" do
    test "can't create two spaces with same slug" do
      assert {:ok, _} =
               BookingSystem.create_space("Space 1", "same-slug", "description 1", 5, 5)

      assert {:error, error} =
               BookingSystem.create_space("Space 2", "same-slug", "description 2", 10, 10)

      error_messages = Ash.Error.error_descriptions(error)

      assert String.contains?(error_messages, "has already been")
    end

    test "can't create two spaces with same name" do
      assert {:ok, _} =
               BookingSystem.create_space("Same Name", "slug-1", "description 1", 5, 5)

      assert {:error, error} =
               BookingSystem.create_space("Same Name", "slug-2", "description 2", 10, 10)

      error_messages = Ash.Error.error_descriptions(error)

      assert String.contains?(error_messages, "has already been")
    end

    test "can create spaces with different names and slugs" do
      assert {:ok, space1} =
               BookingSystem.create_space("Space 1", "slug-1", "description 1", 5, 5)

      assert {:ok, space2} =
               BookingSystem.create_space("Space 2", "slug-2", "description 2", 10, 10)

      assert space1.id != space2.id
    end
  end

  describe "check_availability/4" do
    setup do
      {:ok, space} =
        BookingSystem.create_space(
          "Availability Test Space",
          "availability-test",
          "Test description",
          2,
          3
        )

      %{space: space}
    end

    test "returns :available when no bookings exist", %{space: space} do
      date = Date.utc_today()
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      assert {:ok, :available} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end

    test "returns :available when under public capacity", %{space: space} do
      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      BookingSystem.create_walk_in(
        space.id,
        DateTime.new!(date, start_time, "Etc/UTC"),
        DateTime.new!(date, end_time, "Etc/UTC"),
        "Customer 1",
        "customer1@example.com",
        nil,
        nil
      )

      assert {:ok, :available} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end

    test "returns :over_public_capacity when at public capacity but under real capacity", %{
      space: space
    } do
      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      BookingSystem.create_walk_in(
        space.id,
        DateTime.new!(date, start_time, "Etc/UTC"),
        DateTime.new!(date, end_time, "Etc/UTC"),
        "Customer 1",
        "customer1@example.com",
        nil,
        nil
      )

      BookingSystem.create_walk_in(
        space.id,
        DateTime.new!(date, start_time, "Etc/UTC"),
        DateTime.new!(date, end_time, "Etc/UTC"),
        "Customer 2",
        "customer2@example.com",
        nil,
        nil
      )

      assert {:ok, :over_public_capacity} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end

    test "returns :over_real_capacity when at real capacity", %{space: space} do
      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      for i <- 1..3 do
        BookingSystem.create_walk_in(
          space.id,
          DateTime.new!(date, start_time, "Etc/UTC"),
          DateTime.new!(date, end_time, "Etc/UTC"),
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      assert {:ok, :over_real_capacity} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end

    test "only counts overlapping bookings", %{space: space} do
      date = Date.utc_today()
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      BookingSystem.create_walk_in(
        space.id,
        DateTime.new!(date, ~T[08:00:00], "Etc/UTC"),
        DateTime.new!(date, ~T[09:00:00], "Etc/UTC"),
        "Customer 1",
        "customer1@example.com",
        nil,
        nil
      )

      BookingSystem.create_walk_in(
        space.id,
        DateTime.new!(date, ~T[10:00:00], "Etc/UTC"),
        DateTime.new!(date, ~T[11:00:00], "Etc/UTC"),
        "Customer 2",
        "customer2@example.com",
        nil,
        nil
      )

      assert {:ok, :available} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end

    test "counts partial overlaps", %{space: space} do
      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      BookingSystem.create_walk_in(
        space.id,
        DateTime.new!(date, ~T[08:30:00], "Etc/UTC"),
        DateTime.new!(date, ~T[09:30:00], "Etc/UTC"),
        "Customer 1",
        "customer1@example.com",
        nil,
        nil
      )

      BookingSystem.create_walk_in(
        space.id,
        DateTime.new!(date, ~T[09:30:00], "Etc/UTC"),
        DateTime.new!(date, ~T[10:30:00], "Etc/UTC"),
        "Customer 2",
        "customer2@example.com",
        nil,
        nil
      )

      assert {:ok, :over_public_capacity} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end

    test "does not count pending bookings", %{space: space} do
      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      BookingSystem.create_booking(
        space.id,
        nil,
        date,
        start_time,
        end_time,
        "Customer 1",
        "customer1@example.com",
        nil,
        nil
      )

      BookingSystem.create_booking(
        space.id,
        nil,
        date,
        start_time,
        end_time,
        "Customer 2",
        "customer2@example.com",
        nil,
        nil
      )

      assert {:ok, :available} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end

    test "does not count cancelled bookings", %{space: space} do
      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      {:ok, booking1} =
        BookingSystem.create_walk_in(
          space.id,
          DateTime.new!(date, start_time, "Etc/UTC"),
          DateTime.new!(date, end_time, "Etc/UTC"),
          "Customer 1",
          "customer1@example.com",
          nil,
          nil
        )

      {:ok, _} =
        BookingSystem.create_walk_in(
          space.id,
          DateTime.new!(date, start_time, "Etc/UTC"),
          DateTime.new!(date, end_time, "Etc/UTC"),
          "Customer 2",
          "customer2@example.com",
          nil,
          nil
        )

      BookingSystem.cancel_booking(booking1, "User requested cancellation")

      assert {:ok, :available} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end

    test "does not count rejected bookings", %{space: space} do
      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      {:ok, booking1} =
        BookingSystem.create_booking(
          space.id,
          nil,
          date,
          start_time,
          end_time,
          "Customer 1",
          "customer1@example.com",
          nil,
          nil
        )

      {:ok, _} =
        BookingSystem.create_booking(
          space.id,
          nil,
          date,
          start_time,
          end_time,
          "Customer 2",
          "customer2@example.com",
          nil,
          nil
        )

      BookingSystem.reject_booking(booking1, "Space not available")

      assert {:ok, :available} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end

    test "filters by date correctly", %{space: space} do
      date1 = Date.utc_today()
      date2 = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      for i <- 1..3 do
        BookingSystem.create_walk_in(
          space.id,
          DateTime.new!(date1, start_time, "Etc/UTC"),
          DateTime.new!(date1, end_time, "Etc/UTC"),
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      assert {:ok, :available} =
               BookingSystem.check_availability(space.id, date2, start_time, end_time)
    end

    test "filters by space correctly", %{space: space} do
      {:ok, other_space} =
        BookingSystem.create_space(
          "Other Space",
          "other-space",
          "Another test space",
          2,
          3
        )

      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      for i <- 1..3 do
        BookingSystem.create_walk_in(
          other_space.id,
          DateTime.new!(date, start_time, "Etc/UTC"),
          DateTime.new!(date, end_time, "Etc/UTC"),
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      assert {:ok, :available} =
               BookingSystem.check_availability(space.id, date, start_time, end_time)
    end
  end
end
