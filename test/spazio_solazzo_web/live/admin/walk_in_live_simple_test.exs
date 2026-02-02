defmodule SpazioSolazzoWeb.Admin.WalkInLiveSimpleTest do
  use SpazioSolazzoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SpazioSolazzo.AuthHelpers
  import Ecto.Query

  alias SpazioSolazzo.BookingSystem

  defp create_admin_user do
    user = register_user("admin@example.com", "Admin User")
    # Directly update role to admin using Ecto
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

  describe "walk-in booking creation bug" do
    test "can create booking by directly setting assigns", %{conn: conn, user: user, space: space} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)

      # Simulate the calendar component sending the date_selected message
      send(view.pid, {:date_selected, tomorrow, tomorrow})

      # Give it a moment to process
      :timer.sleep(100)

      # Fill in customer details using the form
      view
      |> form("form[phx-change='update_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com"
      })
      |> render_change()

      # Try to create the booking
      html =
        view
        |> element("button[phx-click='create_booking']")
        |> render_click()

      # Check if it succeeded or failed
      if html =~ "Walk-in booking created successfully" do
        IO.puts("✓ SUCCESS: Booking was created")
      else
        if html =~ "Please fill in all required fields and select a date" do
          IO.puts("✗ BUG FOUND: Error message shown even though all fields are filled!")
          IO.puts("\nThis is the bug the user is experiencing.")
        else
          IO.puts("? Unexpected result")
        end
      end

      # Verify booking was created
      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, tomorrow)

      if length(bookings) > 0 do
        assert true
      else
        flunk("Booking was not created even though all requirements were met")
      end
    end
  end
end
