defmodule SpazioSolazzoWeb.ProfileLiveTest do
  use SpazioSolazzoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SpazioSolazzo.Accounts.User
  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Booking

  setup %{conn: conn} do
    user = register_user("test@example.com", "Test User", "+123456789")
    conn = log_in_user(conn, user)

    %{user: user, conn: conn}
  end

  describe "ProfileLive - Profile Update" do
    test "displays current user information", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/profile")

      assert html =~ user.name
      assert html =~ user.phone_number
      assert html =~ to_string(user.email)
    end

    test "successfully updates profile with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      result =
        view
        |> form("#profile-form", %{
          form: %{
            name: "Updated Test Name",
            phone_number: "+9876543210"
          }
        })
        |> render_submit()

      assert result =~ "Profile updated successfully"
      assert result =~ "+9876543210"
      assert result =~ "Updated Test Name"
    end

    test "shows validation errors for invalid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      result =
        view
        |> form("#profile-form", %{
          form: %{
            name: "",
            phone_number: "+9876543210"
          }
        })
        |> render_change()

      assert result =~ "is required" || result =~ "can&#39;t be blank"
    end

    test "email field is read-only", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/profile")

      assert html =~ "readonly"
      assert html =~ to_string(user.email)
      assert html =~ "Email cannot be changed"
    end
  end

  describe "ProfileLive - Account Deletion" do
    test "displays danger zone with delete account button", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/profile")

      assert html =~ "Danger Zone"
      assert has_element?(view, "button", "Delete My Account")
    end

    test "shows confirmation modal when delete button is clicked", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/profile")

      refute html =~ "Confirm Account Deletion"

      html =
        view
        |> element("button", "Delete My Account")
        |> render_click()

      assert html =~ "Confirm Account Deletion"
      assert html =~ "Yes, Delete My Account"
    end

    test "can toggle delete history checkbox", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element("button", "Delete My Account")
      |> render_click()

      html =
        view
        |> element("#gdpr-consent")
        |> render_click()

      assert html =~ "checked"
    end

    test "successfully deletes account and redirects to sign out", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element("button", "Delete My Account")
      |> render_click()

      view
      |> element("button", "Yes, Delete My Account")
      |> render_click()

      assert_redirect(view, "/sign-out")

      assert {:error, _} = Ash.get(User, user.id)
    end

    test "account deletion with delete_history=false preserves bookings", %{
      conn: conn,
      user: user
    } do
      {space, _time_slot} = create_booking_fixtures()

      {:ok, booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          Date.utc_today(),
          ~T[09:00:00],
          ~T[11:00:00],
          "Test User",
          "test@example.com",
          "+1234567890",
          "test booking"
        )

      booking_id = booking.id

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element("button", "Delete My Account")
      |> render_click()

      view
      |> element("button", "Yes, Delete My Account")
      |> render_click()

      {:ok, preserved_booking} = Ash.get(Booking, booking_id)
      assert preserved_booking.user_id == nil
      assert preserved_booking.customer_name == "Test User"
    end

    test "account deletion with delete_history=true removes all bookings", %{
      conn: conn,
      user: user
    } do
      {space, _time_slot} = create_booking_fixtures()

      {:ok, booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          Date.utc_today(),
          ~T[09:00:00],
          ~T[11:00:00],
          "Test User",
          "test@example.com",
          "+1234567890",
          "test booking"
        )

      booking_id = booking.id

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element("button", "Delete My Account")
      |> render_click()

      view
      |> element("#gdpr-consent")
      |> render_click()

      view
      |> element("button", "Yes, Delete My Account")
      |> render_click()

      assert {:error, _} = Ash.get(Booking, booking_id)
    end
  end

  defp create_booking_fixtures do
    unique_id = :erlang.unique_integer([:positive, :monotonic])

    {:ok, space} =
      BookingSystem.create_space(
        "Test Space #{unique_id}",
        "test-space-#{unique_id}",
        "Test description",
        10,
        12
      )

    {:ok, time_slot} =
      BookingSystem.create_time_slot_template(
        ~T[09:00:00],
        ~T[18:00:00],
        :monday,
        space.id
      )

    {space, time_slot}
  end
end
