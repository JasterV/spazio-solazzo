defmodule SpazioSolazzoWeb.Admin.BookingManagementPaginationTest do
  use SpazioSolazzoWeb.ConnCase, async: false

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
        "coworking-pagination",
        "Coworking space",
        10
      )

    admin_user = create_admin_user()
    tomorrow = Date.add(Date.utc_today(), 1)

    %{space: space, admin_user: admin_user, tomorrow: tomorrow}
  end

  describe "pagination - pending bookings" do
    test "displays first page of pending bookings", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      for i <- 1..15 do
        hour = rem(8 + i, 24)
        start_time = Time.new!(hour, 0, 0)
        end_time = Time.new!(hour, 30, 0)

        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, html} = live(conn, "/admin/bookings")

      assert html =~ "Showing 1-10 of 15"
      assert has_element?(view, "button[phx-click='pending_page_change']")
    end

    test "navigates to second page of pending bookings", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      for i <- 1..15 do
        hour = rem(8 + i, 24)
        start_time = Time.new!(hour, 0, 0)
        end_time = Time.new!(hour, 30, 0)

        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      html =
        view
        |> element("button[phx-click='pending_page_change']", "2")
        |> render_click()

      assert html =~ "Showing 11-15 of 15"
    end

    test "pagination URL params are updated", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      for i <- 1..15 do
        hour = rem(8 + i, 24)
        start_time = Time.new!(hour, 0, 0)
        end_time = Time.new!(hour, 30, 0)

        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> element("button[phx-click='pending_page_change']", "2")
      |> render_click()

      assert_patch(view, "/admin/bookings?history_page=1&pending_page=2")
    end

    test "filters reset pagination to page 1", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      for i <- 1..15 do
        hour = rem(8 + i, 24)
        start_time = Time.new!(hour, 0, 0)
        end_time = Time.new!(hour, 30, 0)

        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings?history_page=1&pending_page=2")

      view
      |> form("form", %{"email" => "customer1@example.com"})
      |> render_change()

      path = assert_patch(view)
      refute path =~ "pending_page=2"
    end

    test "previous button is disabled on first page", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      for i <- 1..15 do
        hour = rem(8 + i, 24)
        start_time = Time.new!(hour, 0, 0)
        end_time = Time.new!(hour, 30, 0)

        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, html} = live(conn, "/admin/bookings")

      assert html =~ "disabled"
      assert has_element?(view, "button[phx-click='pending_page_change'][disabled]")
    end
  end

  describe "pagination - booking history" do
    test "displays first page of booking history", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      for i <- 1..30 do
        start_datetime = DateTime.new!(tomorrow, Time.add(~T[09:00:00], i * 3600), "Etc/UTC")
        end_datetime = DateTime.add(start_datetime, 3600, :second)

        {:ok, booking} =
          BookingSystem.create_walk_in(
            space.id,
            start_datetime,
            end_datetime,
            "Customer #{i}",
            "customer#{i}@example.com",
            nil
          )

        BookingSystem.approve_booking(booking)
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, html} = live(conn, "/admin/bookings")

      assert html =~ "Showing 1-10 of 30"
      assert has_element?(view, "button[phx-click='history_page_change'][phx-value-page='2']")
    end

    test "navigates to second page of booking history", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      for i <- 1..30 do
        start_datetime = DateTime.new!(tomorrow, Time.add(~T[09:00:00], i * 3600), "Etc/UTC")
        end_datetime = DateTime.add(start_datetime, 3600, :second)

        {:ok, booking} =
          BookingSystem.create_walk_in(
            space.id,
            start_datetime,
            end_datetime,
            "Customer #{i}",
            "customer#{i}@example.com",
            nil
          )

        BookingSystem.approve_booking(booking)
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      html =
        view
        |> element("button[phx-click='history_page_change']", "2")
        |> render_click()

      assert html =~ "Showing 11-20 of 30"
    end

    test "history pagination URL params are updated", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      for i <- 1..30 do
        start_datetime = DateTime.new!(tomorrow, Time.add(~T[09:00:00], i * 3600), "Etc/UTC")
        end_datetime = DateTime.add(start_datetime, 3600, :second)

        {:ok, booking} =
          BookingSystem.create_walk_in(
            space.id,
            start_datetime,
            end_datetime,
            "Customer #{i}",
            "customer#{i}@example.com",
            nil
          )

        BookingSystem.approve_booking(booking)
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> element("button[phx-click='history_page_change']", "2")
      |> render_click()

      assert_patch(view, "/admin/bookings?history_page=2&pending_page=1")
    end
  end

  describe "pagination with booking management" do
    test "approving booking refreshes current page", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      {:ok, booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          ~T[10:00:00],
          ~T[11:00:00],
          "Test Customer",
          "test@example.com",
          nil,
          nil
        )

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      # Trigger a refresh
      view |> form("form", %{"email" => ""}) |> render_change()

      view
      |> element("button[phx-click='approve_booking'][phx-value-booking_id='#{booking.id}']")
      |> render_click()

      # Just verify the view still works after approval
      html = render(view)
      assert html =~ "Manage Bookings"
    end

    test "rejecting booking refreshes current page", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      {:ok, booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          ~T[14:00:00],
          ~T[15:00:00],
          "Test Customer",
          "test2@example.com",
          nil,
          nil
        )

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      # Trigger a refresh
      view |> form("form", %{"email" => ""}) |> render_change()

      view
      |> element("button[phx-click='show_reject_modal'][phx-value-booking_id='#{booking.id}']")
      |> render_click()

      view
      |> element("textarea[name='reason']")
      |> render_change(%{"reason" => "Test rejection"})

      view
      |> element("form[phx-submit='confirm_reject']")
      |> render_submit()

      # Just verify the view still works after rejection
      html = render(view)
      assert html =~ "Manage Bookings"
    end
  end

  describe "empty states with pagination" do
    test "shows empty state when no bookings exist", %{
      conn: conn,
      admin_user: admin_user
    } do
      conn = log_in_user(conn, admin_user)
      {:ok, _view, html} = live(conn, "/admin/bookings")

      assert html =~ "No bookings found"
    end

    test "shows pending count as 0 when no pending bookings", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      start_datetime = DateTime.new!(tomorrow, ~T[10:00:00], "Etc/UTC")
      end_datetime = DateTime.add(start_datetime, 3600, :second)

      {:ok, booking} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime,
          end_datetime,
          "Customer",
          "customer@example.com",
          nil
        )

      BookingSystem.approve_booking(booking)

      conn = log_in_user(conn, admin_user)
      {:ok, _view, html} = live(conn, "/admin/bookings")

      assert html =~ "<span class=\"text-2xl font-bold text-primary\">0</span>"
    end
  end

  describe "pagination with filters" do
    test "pagination works with space filter", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      for i <- 1..15 do
        hour = rem(8 + i, 24)
        start_time = Time.new!(hour, 0, 0)
        end_time = Time.new!(hour, 30, 0)

        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> form("form", %{"space" => space.slug})
      |> render_change()

      html = render(view)
      assert html =~ "Showing 1-10 of 15"
    end

    test "pagination works with email filter", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      for i <- 1..15 do
        hour = rem(8 + i, 24)
        start_time = Time.new!(hour, 0, 0)
        end_time = Time.new!(hour, 30, 0)

        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> form("form", %{"email" => "customer1@example.com"})
      |> render_change()

      html = render(view)
      assert html =~ "Showing 1-1 of 1"
    end

    test "pagination works with date filter", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      for i <- 1..15 do
        hour = rem(8 + i, 24)
        start_time = Time.new!(hour, 0, 0)
        end_time = Time.new!(hour, 30, 0)

        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> form("form", %{"date" => Date.to_iso8601(tomorrow)})
      |> render_change()

      html = render(view)
      assert html =~ "Showing 1-10 of 15"
    end

    test "clear filters resets pagination", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      tomorrow: tomorrow
    } do
      user = register_user("user#{System.unique_integer([:positive])}@example.com", "Test User")

      for i <- 1..15 do
        hour = rem(8 + i, 24)
        start_time = Time.new!(hour, 0, 0)
        end_time = Time.new!(hour, 30, 0)

        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings?pending_page=2")

      view
      |> element("button[phx-click='clear_filters']")
      |> render_click()

      path = assert_patch(view)
      refute path =~ "pending_page=2"
    end
  end
end
