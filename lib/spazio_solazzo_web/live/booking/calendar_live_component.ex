defmodule SpazioSolazzoWeb.CalendarLiveComponent do
  @moduledoc """
  LiveView component for rendering booking calendars.
  """

  use SpazioSolazzoWeb, :live_component

  # There are 7 days displayed in the calendar
  @grid_cols 7
  # The calendar can show max 6 weeks for one month
  @grid_rows 6

  def update(assigns, socket) do
    # Initialize navigation date to today's month if not already viewing a month
    beginning_of_month =
      socket.assigns[:beginning_of_month] ||
        Date.utc_today()
        |> Date.beginning_of_month()

    selected_date = assigns[:selected_date] || Date.utc_today()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:beginning_of_month, beginning_of_month)
     |> assign(:selected_date, selected_date)
     |> assign(:today, Date.utc_today())
     |> assign_calendar_grid()}
  end

  def handle_event("prev-month", _params, socket) do
    new_beginning_of_month =
      socket.assigns.beginning_of_month
      |> Date.shift(month: -1)
      |> Date.beginning_of_month()

    {:noreply,
     socket
     |> assign(:beginning_of_month, new_beginning_of_month)
     |> assign_calendar_grid()}
  end

  def handle_event("next-month", _params, socket) do
    new_beginning_of_month =
      socket.assigns.beginning_of_month
      |> Date.shift(month: 1)
      |> Date.beginning_of_month()

    {:noreply,
     socket
     |> assign(:beginning_of_month, new_beginning_of_month)
     |> assign_calendar_grid()}
  end

  def handle_event("select-date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    send(self(), {:date_selected, date})
    {:noreply, assign(socket, :selected_date, date)}
  end

  defp assign_calendar_grid(socket) do
    first = socket.assigns.beginning_of_month
    # Calculate offset to start grid on Monday (Monday = 1)
    day_of_week = Date.day_of_week(socket.assigns.beginning_of_month)
    days_before = day_of_week - 1
    start_date = Date.add(first, -days_before)
    grid = Enum.map(0..(@grid_cols * @grid_rows - 1), fn n -> Date.add(start_date, n) end)

    assign(socket, :grid, grid)
  end

  def render(assigns) do
    ~H"""
    <div id={@id} class="calendar-container">
      <div class="flex items-center justify-between mb-4">
        <button
          type="button"
          phx-click="prev-month"
          phx-target={@myself}
          class="p-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 transition-colors"
        >
          <.icon name="hero-chevron-left" class="w-5 h-5" />
        </button>
        <h3 class="text-lg font-semibold text-slate-900 dark:text-white">
          {Calendar.strftime(@beginning_of_month, "%B %Y")}
        </h3>
        <button
          type="button"
          phx-click="next-month"
          phx-target={@myself}
          class="p-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 transition-colors"
        >
          <.icon name="hero-chevron-right" class="w-5 h-5" />
        </button>
      </div>

      <div class="grid grid-cols-7 text-center text-sm font-medium text-slate-500 dark:text-slate-400 mb-2">
        <span>Mo</span><span>Tu</span><span>We</span><span>Th</span><span>Fr</span><span>Sa</span><span>Su</span>
      </div>

      <div class="grid grid-cols-7 gap-y-2 text-center text-slate-700 dark:text-slate-300">
        <%= for date <- @grid do %>
          <% is_selected = Date.compare(date, @selected_date) == :eq
          is_past = Date.compare(date, @today) == :lt
          is_beginning_of_month = date.month == @beginning_of_month.month %>

          <%= if is_beginning_of_month do %>
            <button
              type="button"
              phx-click={!is_past && "select-date"}
              phx-value-date={Date.to_iso8601(date)}
              phx-target={@myself}
              disabled={is_past}
              class={
                [
                  "p-2 rounded-full transition-colors",
                  # Styling for past dates (disabled)
                  is_past && "cursor-not-allowed opacity-40 text-slate-400 dark:text-slate-600",
                  # Styling for selected date
                  is_selected &&
                    "bg-sky-500 text-white font-bold shadow-md shadow-sky-500/30",
                  # Styling for regular dates
                  !is_past && !is_selected &&
                    "hover:bg-sky-500/20 dark:hover:bg-sky-500/20"
                ]
              }
            >
              {date.day}
            </button>
          <% else %>
            <div class="p-2"></div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
