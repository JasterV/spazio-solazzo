defmodule SpazioSolazzo.CalendarExt do
  @moduledoc """
  Extension module for Calendar with helper date and time formatting functions
  """

  def format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  def format_time_range(%{start_time: start_time, end_time: end_time}) do
    start_time = Calendar.strftime(start_time, "%I:%M %p")
    end_time = Calendar.strftime(end_time, "%I:%M %p")

    "#{start_time} - #{end_time}"
  end

  @doc """
  Formats a datetime as "Feb 10, 2026"
  """
  def format_datetime_date(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end

  @doc """
  Formats a datetime as "Monday, February 10, 2026"
  """
  def format_datetime_date_long(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%A, %B %d, %Y")
  end

  @doc """
  Formats a datetime as "Monday, February 10" (for emails)
  """
  def format_datetime_date_only(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%A, %B %d")
  end

  @doc """
  Formats a time or datetime as "9:00 AM"
  """
  def format_time(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_time()
    |> format_time()
  end

  def format_time(%Time{} = time) do
    Calendar.strftime(time, "%I:%M %p")
  end

  @doc """
  Formats a time range as "9:00 AM - 5:00 PM"
  Takes two Time or DateTime structs
  """
  def format_time_range(%DateTime{} = start_dt, %DateTime{} = end_dt) do
    start_time = DateTime.to_time(start_dt)
    end_time = DateTime.to_time(end_dt)
    format_time_range(start_time, end_time)
  end

  def format_time_range(%Time{} = start_time, %Time{} = end_time) do
    "#{format_time(start_time)} - #{format_time(end_time)}"
  end

  @doc """
  Checks if a booking spans multiple days
  """
  def multi_day?(%DateTime{} = start_datetime, %DateTime{} = end_datetime) do
    start_date = DateTime.to_date(start_datetime)
    end_date = DateTime.to_date(end_datetime)
    Date.compare(start_date, end_date) != :eq
  end

  @doc """
  Formats a datetime range handling both single-day and multi-day bookings.

  Single-day: "Feb 10, 2026 9:00 AM - 5:00 PM"
  Multi-day:  "Feb 10, 2026 9:00 AM - Feb 15, 2026 5:00 PM"
  """
  def format_datetime_range(%DateTime{} = start_datetime, %DateTime{} = end_datetime) do
    if multi_day?(start_datetime, end_datetime) do
      "#{format_datetime_date(start_datetime)} #{format_time(start_datetime)} - #{format_datetime_date(end_datetime)} #{format_time(end_datetime)}"
    else
      "#{format_datetime_date(start_datetime)} #{format_time_range(start_datetime, end_datetime)}"
    end
  end

  @doc """
  Formats the start portion of a datetime range for table display

  Single-day: "Feb 10, 2026 9:00 AM"
  Multi-day:  "Feb 10, 2026 9:00 AM"
  """
  def format_datetime_range_start(%DateTime{} = datetime) do
    "#{format_datetime_date(datetime)} #{format_time(datetime)}"
  end

  @doc """
  Formats the end portion of a datetime range for table display

  Single-day: "5:00 PM" (date not shown)
  Multi-day:  "Feb 15, 2026 5:00 PM"
  """
  def format_datetime_range_end(%DateTime{} = start_datetime, %DateTime{} = end_datetime) do
    if multi_day?(start_datetime, end_datetime) do
      "#{format_datetime_date(end_datetime)} #{format_time(end_datetime)}"
    else
      format_time(end_datetime)
    end
  end

  # There are 7 days displayed in the calendar
  @grid_cols 7
  # The calendar can show max 6 weeks for one month
  @grid_rows 6

  @doc """
  Build a list containing all the dates to be displayed in a
  Calendar grid.

  6 weeks * 7 days = 42 cells
  """
  def build_calendar_grid(date) do
    first_day = Date.beginning_of_month(date)
    # Mon=1, Sun=7
    start_day_of_week = Date.day_of_week(first_day)

    # Calculate days to subtract to get to the previous Monday
    # If starts on Mon (1), sub 0. If Sun (7), sub 6.
    days_to_sub = start_day_of_week - 1
    start_date = Date.add(first_day, -days_to_sub)

    # 6 weeks * 7 days = 42 grid cells
    Enum.map(0..(@grid_cols * @grid_rows - 1), fn i -> Date.add(start_date, i) end)
  end

  @doc "Checks if a date is within a start/end range (inclusive)"
  def date_in_range?(date, start_date, end_date)
      when not is_nil(start_date) and not is_nil(end_date) do
    Date.compare(date, start_date) != :lt and Date.compare(date, end_date) != :gt
  end

  def date_in_range?(_date, _start, _end), do: false
end
