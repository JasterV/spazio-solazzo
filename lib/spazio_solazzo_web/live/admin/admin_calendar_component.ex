defmodule SpazioSolazzoWeb.Admin.AdminCalendarComponent do
  @moduledoc """
  LiveComponent for admin calendar with capacity tracking and multi-day selection.
  """

  use SpazioSolazzoWeb, :live_component

  alias SpazioSolazzo.BookingSystem

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:current_month, fn -> Date.utc_today() end)
      |> assign_new(:multi_day_mode, fn -> false end)
      |> assign_new(:start_date, fn -> nil end)
      |> assign_new(:end_date, fn -> nil end)
      |> assign_new(:selected_date, fn -> nil end)

    # Subscribe to booking events for real-time updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:approved")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:cancelled")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:rejected")
    end

    {:ok, compute_calendar_data(socket)}
  end

  def handle_event("prev_month", _, socket) do
    new_month = Date.add(socket.assigns.current_month, -30)
    first_of_month = Date.beginning_of_month(new_month)

    socket =
      socket
      |> assign(current_month: first_of_month)
      |> compute_calendar_data()

    {:noreply, socket}
  end

  def handle_event("next_month", _, socket) do
    new_month = Date.add(socket.assigns.current_month, 30)
    first_of_month = Date.beginning_of_month(new_month)

    socket =
      socket
      |> assign(current_month: first_of_month)
      |> compute_calendar_data()

    {:noreply, socket}
  end

  def handle_event("toggle_multi_day", _params, socket) do
    # Toggle the current state
    multi_day = !socket.assigns.multi_day_mode

    socket =
      socket
      |> assign(
        multi_day_mode: multi_day,
        start_date: nil,
        end_date: nil,
        selected_date: nil
      )

    # Notify parent of the change
    send(self(), {:multi_day_mode_changed, multi_day})

    {:noreply, socket}
  end

  def handle_event("select_date", %{"date" => date_string}, socket) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        # Check if date is in the past
        if Date.compare(date, Date.utc_today()) == :lt do
          {:noreply, socket}
        else
          # Check capacity
          capacity_status = Map.get(socket.assigns.day_capacities, date, :available)

          if capacity_status == :over_real_capacity do
            {:noreply, socket}
          else
            socket =
              if socket.assigns.multi_day_mode do
                handle_multi_day_selection(socket, date)
              else
                handle_single_day_selection(socket, date)
              end

            {:noreply, socket}
          end
        end

      _ ->
        {:noreply, socket}
    end
  end

  defp handle_single_day_selection(socket, date) do
    socket = assign(socket, selected_date: date, start_date: nil, end_date: nil)

    # Notify parent
    send(self(), {:date_selected, date, date})

    socket
  end

  defp handle_multi_day_selection(socket, date) do
    cond do
      socket.assigns.start_date == nil ->
        # First click - set start date
        assign(socket, start_date: date, end_date: nil, selected_date: nil)

      socket.assigns.end_date == nil ->
        # Second click - set end date
        start_date = socket.assigns.start_date

        {actual_start, actual_end} =
          if Date.compare(date, start_date) == :lt do
            {date, start_date}
          else
            {start_date, date}
          end

        socket = assign(socket, start_date: actual_start, end_date: actual_end)

        # Notify parent
        send(self(), {:date_selected, actual_start, actual_end})

        socket

      true ->
        # Reset and start new selection
        assign(socket, start_date: date, end_date: nil, selected_date: nil)
    end
  end

  defp compute_calendar_data(socket) do
    space_id = socket.assigns.space_id
    current_month = socket.assigns.current_month

    # Get all days in the current month
    first_day = Date.beginning_of_month(current_month)
    last_day = Date.end_of_month(current_month)

    # Calculate capacity for each day
    day_capacities =
      first_day
      |> Date.range(last_day)
      |> Enum.map(fn date ->
        capacity = get_day_capacity(space_id, date)
        {date, capacity}
      end)
      |> Map.new()

    # Build calendar grid
    calendar_weeks = build_calendar_grid(first_day, last_day)

    assign(socket,
      day_capacities: day_capacities,
      calendar_weeks: calendar_weeks,
      month_name: Calendar.strftime(current_month, "%B %Y")
    )
  end

  defp get_day_capacity(space_id, date) do
    # Get the space to check capacities
    case Ash.get(SpazioSolazzo.BookingSystem.Space, space_id) do
      {:ok, space} ->
        # Get all bookings for this day
        case BookingSystem.list_accepted_space_bookings_by_date(space_id, date) do
          {:ok, bookings} ->
            # Count unique booking slots (simplified - counts all bookings)
            booking_count = length(bookings)

            cond do
              booking_count >= space.real_capacity -> :over_real_capacity
              booking_count >= space.public_capacity -> :over_public_capacity
              true -> :available
            end

          _ ->
            :available
        end

      _ ->
        :available
    end
  end

  defp build_calendar_grid(first_day, last_day) do
    # Get the day of week for the first day (1 = Monday, 7 = Sunday)
    start_day_of_week = Date.day_of_week(first_day)

    # Calculate how many empty cells we need at the start
    # We want Sunday to be 0, Monday to be 1, etc.
    padding_days =
      case start_day_of_week do
        7 -> 0
        n -> n
      end

    # Create the padding
    padding = List.duplicate(nil, padding_days)

    # Get all days in the month
    days =
      first_day
      |> Date.range(last_day)
      |> Enum.to_list()

    # Combine and chunk into weeks
    (padding ++ days)
    |> Enum.chunk_every(7, 7, List.duplicate(nil, 7))
  end

  defp day_in_range?(_date, nil, nil, nil), do: false

  defp day_in_range?(date, selected, nil, nil) when not is_nil(selected),
    do: Date.compare(date, selected) == :eq

  defp day_in_range?(date, nil, start_date, nil) when not is_nil(start_date),
    do: Date.compare(date, start_date) == :eq

  defp day_in_range?(date, nil, start_date, end_date)
       when not is_nil(start_date) and not is_nil(end_date) do
    Date.compare(date, start_date) != :lt and Date.compare(date, end_date) != :gt
  end

  defp day_in_range?(_, _, _, _), do: false

  defp is_start_date?(_date, nil, _), do: false
  defp is_start_date?(date, start_date, _), do: Date.compare(date, start_date) == :eq

  defp is_end_date?(_date, _, nil), do: false
  defp is_end_date?(date, _, end_date), do: Date.compare(date, end_date) == :eq

  defp day_classes(date, assigns) do
    # Extract capacity status for the given date
    capacity = Map.get(assigns.day_capacities, date, :available)
    is_past = Date.compare(date, Date.utc_today()) == :lt
    in_range = day_in_range?(date, assigns.selected_date, assigns.start_date, assigns.end_date)
    is_start = is_start_date?(date, assigns.start_date, assigns.end_date)
    is_end = is_end_date?(date, assigns.start_date, assigns.end_date)

    base = "aspect-square flex flex-col items-center justify-center transition-all"

    cond do
      is_past ->
        [base, "text-slate-400 dark:text-slate-600 cursor-not-allowed opacity-50"]

      capacity == :over_real_capacity ->
        [
          base,
          "bg-red-50 dark:bg-red-900/20 text-slate-400 dark:text-slate-500 border border-red-300 dark:border-red-800/30 cursor-not-allowed"
        ]

      in_range && assigns.multi_day_mode && assigns.end_date != nil ->
        cond do
          is_start ->
            [
              base,
              "rounded-l-lg bg-primary text-white shadow-lg shadow-primary/30 relative z-10 hover:scale-105"
            ]

          is_end ->
            [
              base,
              "rounded-r-lg bg-primary text-white shadow-lg shadow-primary/30 relative z-10 hover:scale-105"
            ]

          true ->
            [
              base,
              "bg-primary/20 dark:bg-primary/30 text-slate-900 dark:text-white border-y border-primary/20 dark:border-primary/50"
            ]
        end

      in_range ->
        [
          base,
          "rounded-lg bg-primary text-white shadow-lg shadow-primary/30 relative z-10 hover:scale-105"
        ]

      capacity == :over_public_capacity ->
        [
          base,
          "rounded-lg bg-orange-100 dark:bg-orange-900/20 hover:bg-orange-200 dark:hover:bg-orange-900/40 text-slate-700 dark:text-slate-200 border border-transparent hover:border-orange-500 dark:hover:border-orange-600"
        ]

      true ->
        [
          base,
          "rounded-lg bg-green-100 dark:bg-green-900/20 hover:bg-green-200 dark:hover:bg-green-900/40 text-slate-700 dark:text-slate-200 border border-transparent hover:border-green-500 dark:hover:border-green-600"
        ]
    end
  end

  defp capacity_indicator_color(capacity) do
    case capacity do
      :available -> "bg-green-500"
      :over_public_capacity -> "bg-orange-500"
      :over_real_capacity -> "bg-red-500"
      _ -> "bg-slate-300"
    end
  end
end
