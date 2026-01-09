defmodule SpazioSolazzo.Accounts.UserTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.Accounts.User
  alias SpazioSolazzo.Accounts
  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Booking

  describe "update_profile" do
    test "allows user to update their own name and phone_number" do
      user = create_test_user("test@example.com")

      {:ok, updated_user} =
        Accounts.update_profile(user, "Updated Name", "+9876543210", actor: user)

      assert updated_user.name == "Updated Name"
      assert updated_user.phone_number == "+9876543210"
      assert to_string(updated_user.email) == "test@example.com"
    end

    test "prevents user from updating another user's profile" do
      user1 = create_test_user("user1@example.com")
      user2 = create_test_user("user2@example.com")

      result =
        Accounts.update_profile(user2, "Hacker", "1235837", actor: user1)

      assert {:error, %Ash.Error.Forbidden{}} = result
    end

    test "validates that name is present" do
      user = create_test_user("test@example.com")

      result =
        Accounts.update_profile(user, "", "+9876543210", actor: user)

      assert {:error, changeset} = result
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end
  end

  describe "terminate_account with delete_history: false (anonymization)" do
    test "deletes user but preserves bookings with nullified user_id" do
      user = create_test_user("delete@example.com")
      {_space, asset, time_slot} = create_booking_fixtures()

      {:ok, booking1} =
        BookingSystem.create_booking(
          time_slot.id,
          asset.id,
          user.id,
          Date.utc_today(),
          "John Doe",
          "john@example.com",
          "+393627384027",
          "test booking 1"
        )

      {:ok, booking2} =
        BookingSystem.create_booking(
          time_slot.id,
          asset.id,
          user.id,
          Date.add(Date.utc_today(), 1),
          "Jane Doe",
          "jane@example.com",
          "+393627384028",
          "test booking 2"
        )

      booking1_id = booking1.id
      booking2_id = booking2.id

      :ok = Accounts.terminate_account(user, false, actor: user)

      assert {:error, _} = Ash.get(User, user.id)

      {:ok, preserved_booking1} = Ash.get(Booking, booking1_id)
      {:ok, preserved_booking2} = Ash.get(Booking, booking2_id)

      assert preserved_booking1.user_id == nil
      assert preserved_booking2.user_id == nil

      assert preserved_booking1.customer_name == "John Doe"
      assert preserved_booking2.customer_name == "Jane Doe"
    end

    test "cancels future confirmed bookings before anonymizing" do
      user = create_test_user("cancel@example.com")
      {_space, asset, time_slot} = create_booking_fixtures()

      future_date = Date.add(Date.utc_today(), 7)

      {:ok, future_booking} =
        BookingSystem.create_booking(
          time_slot.id,
          asset.id,
          user.id,
          future_date,
          "Future User",
          "future@example.com",
          "+393627384029",
          "future booking"
        )

      {:ok, past_booking} =
        BookingSystem.create_booking(
          time_slot.id,
          asset.id,
          user.id,
          Date.add(Date.utc_today(), -7),
          "Past User",
          "past@example.com",
          "+393627384030",
          "past booking"
        )

      future_booking_id = future_booking.id
      past_booking_id = past_booking.id

      :ok = Accounts.terminate_account(user, false, actor: user)

      {:ok, cancelled_booking} = Ash.get(Booking, future_booking_id, authorize?: false)
      {:ok, preserved_past_booking} = Ash.get(Booking, past_booking_id, authorize?: false)

      assert cancelled_booking.state == :cancelled
      assert cancelled_booking.user_id == nil

      assert preserved_past_booking.user_id == nil
    end
  end

  describe "terminate_account with delete_history: true (hard delete)" do
    test "deletes user and all associated bookings permanently" do
      user = create_test_user("harddelete@example.com")
      {_space, asset, time_slot} = create_booking_fixtures()

      {:ok, booking1} =
        BookingSystem.create_booking(
          time_slot.id,
          asset.id,
          user.id,
          Date.utc_today(),
          "Delete Me",
          "deleteme@example.com",
          "+393627384031",
          "test booking"
        )

      {:ok, booking2} =
        BookingSystem.create_booking(
          time_slot.id,
          asset.id,
          user.id,
          Date.add(Date.utc_today(), 1),
          "Delete Me Too",
          "deletemetoo@example.com",
          "+393627384032",
          "test booking 2"
        )

      booking1_id = booking1.id
      booking2_id = booking2.id

      :ok = Accounts.terminate_account(user, true, actor: user)

      assert {:error, _} = Ash.get(User, user.id)
      assert {:error, _} = Ash.get(Booking, booking1_id, authorize?: false)
      assert {:error, _} = Ash.get(Booking, booking2_id, authorize?: false)
    end
  end

  describe "terminate_account authorization" do
    test "prevents user from deleting another user's account" do
      user1 = create_test_user("user1@example.com")
      user2 = create_test_user("user2@example.com")

      result = Accounts.terminate_account(user2, false, actor: user1)

      assert {:error, %Ash.Error.Forbidden{}} = result
    end
  end

  defp create_test_user(email) do
    {:ok, user} =
      SpazioSolazzo.Repo.insert(%User{
        id: Ash.UUID.generate(),
        email: email,
        name: "Test User",
        phone_number: "+1234567890"
      })

    user
  end

  defp create_booking_fixtures do
    unique_id = :erlang.unique_integer([:positive, :monotonic])

    {:ok, space} =
      BookingSystem.create_space(
        "Test Space #{unique_id}",
        "test-space-#{unique_id}",
        "Test description"
      )

    {:ok, asset} = BookingSystem.create_asset("Test Asset", space.id)

    {:ok, time_slot} =
      BookingSystem.create_time_slot_template(
        ~T[09:00:00],
        ~T[18:00:00],
        :monday,
        space.id
      )

    {space, asset, time_slot}
  end
end
