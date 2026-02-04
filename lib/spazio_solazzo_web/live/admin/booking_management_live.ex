defmodule SpazioSolazzoWeb.Admin.BookingManagementLive do
  @moduledoc """
  Admin booking management tool for reviewing and managing all booking requests.
  Refactored to use URL as the Single Source of Truth.
  """

  use SpazioSolazzoWeb, :live_view

  import SpazioSolazzoWeb.AdminBookingManagementComponents
  alias SpazioSolazzo.BookingSystem

  @pending_limit 10
  @history_limit 10

  def mount(_params, _session, socket) do
    {:ok, spaces} = Ash.read(SpazioSolazzo.BookingSystem.Space)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:approved")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:cancelled")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:rejected")
    end

    {:ok,
     assign(socket,
       spaces: spaces,
       expanded_booking_ids: MapSet.new(),
       show_reject_modal: false,
       rejecting_booking_id: nil,
       rejection_reason: ""
     )}
  end

  def handle_params(params, _uri, socket) do
    # Destructure params with defaults. This ensures all keys exist.
    %{
      "space" => space_slug,
      "email" => email,
      "date" => date_str,
      "pending_page" => pending_str,
      "history_page" => history_str
    } =
      Map.merge(
        %{
          "space" => nil,
          "email" => "",
          "date" => nil,
          "pending_page" => "1",
          "history_page" => "1"
        },
        params
      )

    socket =
      socket
      |> assign(
        filter_space: parse_string(space_slug),
        filter_email: email,
        filter_date: parse_date(date_str),
        pending_page_number: parse_page(pending_str),
        history_page_number: parse_page(history_str)
      )
      |> fetch_bookings()

    {:noreply, socket}
  end

  def handle_event(
        "filter_bookings",
        %{"date" => date, "space" => space, "email" => email},
        socket
      ) do
    params = %{
      "date" => date,
      "space" => space,
      "email" => email,
      # Reset pagination to page 1 when filtering
      "pending_page" => "1",
      "history_page" => "1"
    }

    {:noreply, push_patch(socket, to: build_filter_path(socket, params), replace: true)}
  end

  def handle_event("clear_filters", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/bookings", replace: true)}
  end

  def handle_event("pending_page_change", %{"page" => page}, socket) do
    {:noreply, push_patch(socket, to: build_filter_path(socket, %{"pending_page" => page}))}
  end

  def handle_event("history_page_change", %{"page" => page}, socket) do
    {:noreply, push_patch(socket, to: build_filter_path(socket, %{"history_page" => page}))}
  end

  def handle_event("toggle_expand", %{"booking_id" => booking_id}, socket) do
    expanded =
      if MapSet.member?(socket.assigns.expanded_booking_ids, booking_id) do
        MapSet.delete(socket.assigns.expanded_booking_ids, booking_id)
      else
        MapSet.put(socket.assigns.expanded_booking_ids, booking_id)
      end

    {:noreply, assign(socket, expanded_booking_ids: expanded)}
  end

  def handle_event("approve_booking", %{"booking_id" => booking_id}, socket) do
    case Ash.get(BookingSystem.Booking, booking_id) do
      {:ok, booking} ->
        BookingSystem.approve_booking(booking)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Booking not found")}
    end
  end

  def handle_event("show_reject_modal", %{"booking_id" => booking_id}, socket) do
    {:noreply,
     assign(socket,
       show_reject_modal: true,
       rejecting_booking_id: booking_id,
       rejection_reason: ""
     )}
  end

  def handle_event("hide_reject_modal", _, socket) do
    {:noreply, assign(socket, show_reject_modal: false, rejecting_booking_id: nil)}
  end

  def handle_event("stop_propagation", _, socket), do: {:noreply, socket}

  def handle_event("update_rejection_reason", %{"reason" => reason}, socket) do
    {:noreply, assign(socket, rejection_reason: reason)}
  end

  def handle_event("confirm_reject", _, socket) do
    %{rejecting_booking_id: id, rejection_reason: reason} = socket.assigns

    if String.trim(reason) == "" do
      {:noreply, put_flash(socket, :error, "Please provide a rejection reason")}
    else
      case Ash.get(BookingSystem.Booking, id) do
        {:ok, booking} ->
          BookingSystem.reject_booking(booking, reason)

          socket =
            socket
            |> assign(show_reject_modal: false, rejecting_booking_id: nil)
            |> put_flash(:info, "Booking rejected")

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Booking not found")}
      end
    end
  end

  def handle_info(%{topic: "booking:" <> _}, socket) do
    {:noreply, fetch_bookings(socket)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp fetch_bookings(socket) do
    %{
      filter_space: space_slug,
      filter_email: email,
      filter_date: date,
      pending_page_number: pending_page,
      history_page_number: history_page,
      spaces: spaces
    } = socket.assigns

    space_id =
      spaces
      |> Enum.find(%{}, fn s -> s.slug == space_slug end)
      |> Map.get(:id, nil)

    query_email = parse_string(email)
    pending_offset = (pending_page - 1) * @pending_limit
    history_offset = (history_page - 1) * @history_limit

    {:ok, pending_data} =
      BookingSystem.read_pending_bookings(space_id, query_email, date,
        page: [limit: @pending_limit, offset: pending_offset, count: true],
        load: [:space, :user]
      )

    {:ok, history_data} =
      BookingSystem.read_booking_history(space_id, query_email, date,
        page: [limit: @history_limit, offset: history_offset, count: true],
        load: [:space, :user]
      )

    assign(socket, pending_page: pending_data, history_page: history_data)
  end

  defp build_filter_path(socket, overrides) do
    current = %{
      "space" => socket.assigns.filter_space,
      "email" => socket.assigns.filter_email,
      "date" => socket.assigns.filter_date,
      "pending_page" => socket.assigns.pending_page_number,
      "history_page" => socket.assigns.history_page_number
    }

    # Merge overrides -> Filter empty values -> Encode
    params =
      current
      |> Map.merge(overrides)
      |> Enum.reduce(%{}, fn
        {_k, nil}, acc -> acc
        {_k, ""}, acc -> acc
        {"date", %Date{} = d}, acc -> Map.put(acc, "date", Date.to_iso8601(d))
        {k, v}, acc -> Map.put(acc, k, v)
      end)

    ~p"/admin/bookings"
    |> URI.parse()
    |> URI.append_query(URI.encode_query(params))
    |> URI.to_string()
  end

  defp parse_page(nil), do: 1
  defp parse_page(""), do: 1

  defp parse_page(value) do
    case Integer.parse(value) do
      {n, _} when n > 0 -> n
      _ -> 1
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_string(nil), do: nil
  defp parse_string(""), do: nil
  defp parse_string(value), do: value
end
