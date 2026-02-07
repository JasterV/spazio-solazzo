defmodule SpazioSolazzoWeb.BookingCalendarLiveComponent do
  @moduledoc """
  The calendar displayed in the space booking view.
  It allows users to select a date in a beautifully-styled calendar grid.
  """
  
  use SpazioSolazzoWeb, :live_component
  alias SpazioSolazzo.CalendarExt

  def update(assigns, socket) do
    first_day =
      assigns[:first_day_of_month] ||
        socket.assigns[:first_day_of_month] ||
        Date.utc_today() |> Date.beginning_of_month()

    grid = CalendarExt.build_calendar_grid(first_day)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:first_day_of_month, first_day)
     |> assign(:grid, grid)}
  end

  def handle_event("prev-month", _, socket) do
    new_date =
      socket.assigns.first_day_of_month
      |> Date.shift(month: -1)
      |> Date.beginning_of_month()

    {:noreply,
     assign(socket, first_day_of_month: new_date, grid: CalendarExt.build_calendar_grid(new_date))}
  end

  def handle_event("next-month", _, socket) do
    new_date =
      socket.assigns.first_day_of_month
      |> Date.shift(month: 1)
      |> Date.beginning_of_month()

    {:noreply,
     assign(socket, first_day_of_month: new_date, grid: CalendarExt.build_calendar_grid(new_date))}
  end

  # --- Selection (Parent IS notified) ---

  def handle_event("select-date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)

    send(self(), {:date_selected, date})

    {:noreply, assign(socket, :selected_date, date)}
  end

  def render(assigns) do
    ~H"""
    <div class="calendar-container">
      <%!-- Header --%>
      <div class="flex items-center justify-between mb-4">
        <button
          type="button"
          phx-click="prev-month"
          phx-target={@myself}
          class="p-2 hover:bg-base-200 rounded-full"
        >
          <.icon name="hero-chevron-left" class="w-5 h-5" />
        </button>
        <h3 class="text-lg font-bold capitalize select-none">
          {Calendar.strftime(@first_day_of_month, "%B %Y")}
        </h3>
        <button
          type="button"
          phx-click="next-month"
          phx-target={@myself}
          class="p-2 hover:bg-base-200 rounded-full"
        >
          <.icon name="hero-chevron-right" class="w-5 h-5" />
        </button>
      </div>

      <div class="grid grid-cols-7 text-center text-sm font-medium opacity-70 mb-2 select-none">
        <span>Mo</span><span>Tu</span><span>We</span><span>Th</span><span>Fr</span><span>Sa</span><span>Su</span>
      </div>

      <div class="grid grid-cols-7 gap-1">
        <%= for date <- @grid do %>
          <% is_current_month = date.month == @first_day_of_month.month
          is_selected = @selected_date == date
          is_past = Date.compare(date, Date.utc_today()) == :lt %>

          <%= if is_current_month do %>
            <button
              type="button"
              phx-click={!is_past && "select-date"}
              phx-value-date={date}
              phx-target={@myself}
              disabled={is_past}
              class={[
                "p-2 rounded-full w-full aspect-square flex items-center justify-center transition-colors",
                is_past && "cursor-not-allowed opacity-40 text-neutral",
                is_selected && "bg-secondary text-white font-bold shadow-md",
                !is_past && !is_selected && "hover:bg-secondary/20"
              ]}
            >
              {date.day}
            </button>
          <% else %>
            <div class="p-2 w-full aspect-square"></div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
