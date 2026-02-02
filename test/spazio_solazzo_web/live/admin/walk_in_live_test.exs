defmodule SpazioSolazzoWeb.Admin.WalkInLiveTest do
  use SpazioSolazzoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SpazioSolazzo.AuthHelpers
  import Ecto.Query

  alias SpazioSolazzo.BookingSystem

  defp create_admin_user do
    user = register_user("admin@example.com", "Admin User")
    {:ok, uuid} = Ecto.UUID.dump(user.id)

    from(u in "users", where: u.id == ^uuid)
    |> SpazioSolazzo.Repo.update_all(set: [role: "admin"])

    user
  end

  setup do
    {:ok, space} =
      BookingSystem.create_space(
        "Coworking",
        "coworking",
        "Coworking space",
        5,
        10
      )

    user = create_admin_user()

    %{space: space, user: user}
  end

  describe "walk-in booking form" do
    test "displays the form with calendar and customer details", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      assert has_element?(view, "form[phx-change='update_customer_details']")
      assert has_element?(view, "input[name='customer_name']")
      assert has_element?(view, "input[name='customer_email']")
      assert has_element?(view, "button[phx-click='create_booking']")
    end

    test "creates single-day walk-in booking successfully", %{
      conn: conn,
      user: user,
      space: space
    } do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)

      # Simulate date selection by sending message to LiveView
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      # Fill in customer details
      view
      |> form("form[phx-change='update_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com"
      })
      |> render_change()

      # Submit the form
      html =
        view
        |> element("button[phx-click='create_booking']")
        |> render_click()

      assert html =~ "Walk-in booking created successfully"

      # Verify booking was created
      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, tomorrow)
      assert length(bookings) == 1
      booking = hd(bookings)
      assert booking.customer_name == "John Doe"
      assert booking.customer_email == "john@example.com"
      assert booking.state == :accepted
    end

    test "shows error when no date is selected", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      # Fill in customer details without selecting a date
      view
      |> form("form[phx-change='update_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com"
      })
      |> render_change()

      # Try to submit
      html =
        view
        |> element("button[phx-click='create_booking']")
        |> render_click()

      assert html =~ "Please fill in all required fields and select a date"
    end

    test "shows error when customer name is missing", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      view
      |> form("form[phx-change='update_customer_details']", %{
        "customer_email" => "john@example.com"
      })
      |> render_change()

      html =
        view
        |> element("button[phx-click='create_booking']")
        |> render_click()

      assert html =~ "Please fill in all required fields and select a date"
    end

    test "shows error when customer email is missing", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      view
      |> form("form[phx-change='update_customer_details']", %{
        "customer_name" => "John Doe"
      })
      |> render_change()

      html =
        view
        |> element("button[phx-click='create_booking']")
        |> render_click()

      assert html =~ "Please fill in all required fields and select a date"
    end

    test "creates multi-day walk-in booking", %{conn: conn, user: user, space: space} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      # Select date range (3 days)
      start_date = Date.add(Date.utc_today(), 1)
      end_date = Date.add(Date.utc_today(), 3)

      send(view.pid, {:date_selected, start_date, end_date})
      :timer.sleep(50)

      # Fill in customer details
      view
      |> form("form[phx-change='update_customer_details']", %{
        "customer_name" => "Jane Smith",
        "customer_email" => "jane@example.com"
      })
      |> render_change()

      # Submit the form
      html =
        view
        |> element("button[phx-click='create_booking']")
        |> render_click()

      assert html =~ "Walk-in booking created successfully"

      # Verify booking was created and spans multiple days
      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, start_date)
      assert length(bookings) == 1
      booking = hd(bookings)
      assert booking.customer_name == "Jane Smith"

      # Verify booking appears on all days in the range
      {:ok, day2_bookings} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, Date.add(start_date, 1))

      assert length(day2_bookings) == 1

      {:ok, day3_bookings} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, end_date)

      assert length(day3_bookings) == 1
    end

    test "includes optional phone and comment", %{conn: conn, user: user, space: space} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      view
      |> form("form[phx-change='update_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com",
        "customer_phone" => "+39 1234567890",
        "customer_comment" => "Special request"
      })
      |> render_change()

      html =
        view
        |> element("button[phx-click='create_booking']")
        |> render_click()

      assert html =~ "Walk-in booking created successfully"

      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, tomorrow)
      booking = hd(bookings)
      assert booking.customer_phone == "+39 1234567890"
      assert booking.customer_comment == "Special request"
    end

    test "clears form after successful booking", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      view
      |> form("form[phx-change='update_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com"
      })
      |> render_change()

      html =
        view
        |> element("button[phx-click='create_booking']")
        |> render_click()

      assert html =~ "Walk-in booking created successfully"

      # Check that form inputs are cleared by verifying empty values
      html = render(view)
      assert html =~ "Not selected"
      assert html =~ ~s(value="")
    end
  end
end
