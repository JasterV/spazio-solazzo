defmodule SpazioSolazzoWeb.Admin.AdminCalendarComponent do
  @moduledoc """
  Admin calendar for managing bookings, visualizing capacity, and selecting date ranges.
  """
  use SpazioSolazzoWeb, :live_component

  alias SpazioSolazzo.CalendarExt

  @doc "Resets the calendar selection state."
  def reset(id) do
    send_update(__MODULE__, id: id, reset: true)
  end

  def update(%{reset: true}, socket) do
    socket =
      socket
      |> assign(start_date: nil)
      |> assign(end_date: nil)
      |> assign(selected_date: nil)

    {:ok, socket}
  end

  def update(assigns, socket) do
    first_day =
      assigns[:first_day_of_month] ||
        socket.assigns[:first_day_of_month] ||
        Date.utc_today() |> Date.beginning_of_month()

    grid = CalendarExt.build_calendar_grid(first_day)

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:booking_counts, fn -> %{} end)
      |> assign_new(:multi_day_mode, fn -> false end)
      |> assign_new(:start_date, fn -> nil end)
      |> assign_new(:end_date, fn -> nil end)
      |> assign_new(:selected_date, fn -> nil end)
      |> assign(first_day_of_month: first_day)
      |> assign(grid: grid)

    {:ok, socket}
  end

  def handle_event("prev_month", _, socket) do
    new_date = Date.shift(socket.assigns.first_day_of_month, month: -1)

    grid = CalendarExt.build_calendar_grid(new_date)

    socket =
      socket
      |> assign(first_day_of_month: new_date)
      |> assign(grid: grid)

    send(self(), {:change_month, new_date})

    {:noreply, socket}
  end

  def handle_event("next_month", _, socket) do
    new_date = Date.shift(socket.assigns.first_day_of_month, month: 1)

    grid = CalendarExt.build_calendar_grid(new_date)

    socket =
      socket
      |> assign(first_day_of_month: new_date)
      |> assign(grid: grid)

    send(self(), {:change_month, new_date})

    {:noreply, socket}
  end

  def handle_event("toggle_multi_day", _, socket) do
    new_mode = !socket.assigns.multi_day_mode

    send(self(), {:multi_day_mode_toggle, new_mode})

    {:noreply,
     assign(socket,
       multi_day_mode: new_mode,
       start_date: nil,
       end_date: nil,
       selected_date: nil
     )}
  end

  def handle_event("select_date", %{"date" => d}, socket) do
    date = Date.from_iso8601!(d)

    if socket.assigns.multi_day_mode do
      handle_multi_select(socket, date)
    else
      send(self(), {:date_selected, date, date})
      {:noreply, assign(socket, selected_date: date, start_date: nil, end_date: nil)}
    end
  end

  defp handle_multi_select(
         %{assigns: %{start_date: start_date, end_date: end_date}} = socket,
         date
       ) do
    cond do
      is_nil(start_date) ->
        # Start Selection
        {:noreply, assign(socket, start_date: date)}

      is_nil(end_date) ->
        # End Selection (Order correctly)
        {new_start, new_end} =
          if Date.compare(date, start_date) == :lt,
            do: {date, start_date},
            else: {start_date, date}

        send(self(), {:date_selected, new_start, new_end})
        {:noreply, assign(socket, start_date: new_start, end_date: new_end)}

      true ->
        # Reset
        {:noreply, assign(socket, start_date: date, end_date: nil)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <%!-- Toolbar --%>
      <div
        class="flex items-center gap-3 p-3 bg-slate-50 dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-700"
        phx-click="toggle_multi_day"
        phx-target={@myself}
      >
        <input
          type="checkbox"
          checked={@multi_day_mode}
          class="checkbox checkbox-primary checkbox-sm pointer-events-none"
        />
        <label class="text-sm font-semibold select-none cursor-pointer">
          Enable Multi-Day Selection
        </label>
      </div>

      <div class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-2xl p-4 shadow-sm">
        <div class="flex items-center justify-between mb-4">
          <button phx-click="prev_month" phx-target={@myself} class="btn btn-sm btn-ghost btn-circle">
            <.icon name="hero-chevron-left" />
          </button>
          <h4 class="font-bold text-lg capitalize">
            {Calendar.strftime(@first_day_of_month, "%B %Y")}
          </h4>
          <button phx-click="next_month" phx-target={@myself} class="btn btn-sm btn-ghost btn-circle">
            <.icon name="hero-chevron-right" />
          </button>
        </div>

        <div class="grid grid-cols-7 mb-2 text-center text-xs font-bold text-slate-400 uppercase tracking-wider">
          <span>Su</span><span>Mo</span><span>Tu</span><span>We</span><span>Th</span><span>Fr</span><span>Sa</span>
        </div>

        <div class="grid grid-cols-7 gap-1 md:gap-2">
          <%= for date <- @grid do %>
            <% # Uses the booking_counts passed from parent
            count = Map.get(@booking_counts, date, 0)
            is_current = date.month == @first_day_of_month.month %>

            <div class={[day_classes(date, assigns), !is_current && "opacity-25 grayscale"]}>
              <%!-- Header Row: Date & Badge --%>
              <div class="flex justify-between items-start">
                <span class="text-xs font-bold">{date.day}</span>
                <%= if count > 0 and is_current do %>
                  <.link
                    navigate={~p"/admin/bookings?date=#{Date.to_string(date)}"}
                    class="badge badge-info badge-xs text-white font-bold hover:scale-110 transition-transform"
                    title={"#{count} bookings"}
                  >
                    {count}
                  </.link>
                <% end %>
              </div>

              <%= if @multi_day_mode do %>
                {if @start_date == date, do: echo_label("Start")}
                {if @end_date == date, do: echo_label("End")}
              <% end %>

              <%= if Date.compare(date, Date.utc_today()) != :lt do %>
                <button
                  phx-click="select_date"
                  phx-value-date={date}
                  phx-target={@myself}
                  class="absolute inset-0 w-full h-full"
                >
                </button>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp day_classes(date, %{
         start_date: start_date,
         end_date: end_date,
         selected_date: selected_date,
         multi_day_mode: multi
       }) do
    is_past = Date.compare(date, Date.utc_today()) == :lt
    is_start = start_date == date
    is_end = end_date == date
    is_sel = selected_date == date
    in_range = CalendarExt.date_in_range?(date, start_date, end_date)

    base =
      "relative aspect-square flex flex-col p-2 transition-all border border-slate-200 dark:border-slate-700 "

    cond do
      is_past ->
        base <> "bg-slate-50 dark:bg-slate-800/50 text-slate-300 cursor-not-allowed"

      is_start ->
        base <> "bg-primary text-white rounded-l-lg z-10 shadow-md"

      is_end ->
        base <> "bg-primary text-white rounded-r-lg z-10 shadow-md"

      in_range && multi ->
        base <> "bg-primary/20 text-slate-900 dark:text-white"

      is_sel ->
        base <> "bg-primary text-white rounded-lg shadow-md"

      true ->
        base <> "bg-white dark:bg-slate-800 hover:bg-slate-50 text-slate-700 dark:text-slate-200"
    end
  end

  defp echo_label(text) do
    assigns = %{text: text}

    ~H"""
    <span class="mt-auto text-[10px] uppercase font-black tracking-tighter">{@text}</span>
    """
  end
end
