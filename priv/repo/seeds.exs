# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias SpazioSolazzo.BookingSystem

IO.puts("Seeding Spazio Solazzo booking system...")

# Check if database is already seeded
case BookingSystem.Space |> Ash.read() do
  {:ok, [_ | _] = spaces} ->
    IO.puts("✓ Database already seeded (found #{length(spaces)} spaces)")
    IO.puts("✓ Run 'mix ecto.reset' to reset and re-seed the database")
    System.halt(0)

  _ ->
    :ok
end

# Create Coworking Space
{:ok, coworking} =
  BookingSystem.Space
  |> Ash.Changeset.for_create(:create, %{
    name: "Coworking",
    slug: "coworking",
    description: "Flexible desk spaces for remote work"
  })
  |> Ash.create()

IO.puts("✓ Created Coworking space")

# Create Meeting Room Space
{:ok, meeting} =
  BookingSystem.Space
  |> Ash.Changeset.for_create(:create, %{
    name: "Meeting Room",
    slug: "meeting",
    description: "Private conference rooms by the hour"
  })
  |> Ash.create()

IO.puts("✓ Created Meeting Room space")

# Create Music Studio Space
{:ok, music} =
  BookingSystem.Space
  |> Ash.Changeset.for_create(:create, %{
    name: "Music Studio",
    slug: "music",
    description: "Evening recording sessions"
  })
  |> Ash.create()

IO.puts("✓ Created Music Studio space")

# Create Coworking Tables (Assets)
tables =
  for i <- 1..5 do
    {:ok, table} =
      BookingSystem.Asset
      |> Ash.Changeset.for_create(:create, %{
        name: "Table #{i}",
        space_id: coworking.id
      })
      |> Ash.create()

    table
  end

IO.puts("✓ Created #{length(tables)} coworking tables")

# Create Meeting Room Asset
{:ok, _meeting_room} =
  BookingSystem.Asset
  |> Ash.Changeset.for_create(:create, %{
    name: "Main Conference Room",
    space_id: meeting.id
  })
  |> Ash.create()

IO.puts("✓ Created meeting room asset")

# Create Music Studio Asset
{:ok, _studio} =
  BookingSystem.Asset
  |> Ash.Changeset.for_create(:create, %{
    name: "Recording Studio",
    space_id: music.id
  })
  |> Ash.create()

IO.puts("✓ Created music studio asset")

# Create Coworking Time Slot Templates for each weekday
coworking_slots = [
  %{name: "Morning (9am-1pm)", start_time: ~T[09:00:00], end_time: ~T[13:00:00]},
  %{name: "Afternoon (2pm-6pm)", start_time: ~T[14:00:00], end_time: ~T[18:00:00]}
]

weekdays = [:monday, :tuesday, :wednesday, :thursday, :friday]

for day <- weekdays, slot <- coworking_slots do
  {:ok, _} =
    BookingSystem.TimeSlotTemplate
    |> Ash.Changeset.for_create(
      :create,
      slot |> Map.put(:space_id, coworking.id) |> Map.put(:day_of_week, day)
    )
    |> Ash.create()
end

IO.puts(
  "✓ Created #{length(weekdays) * length(coworking_slots)} coworking time slots across weekdays"
)

# Create Meeting Room Hourly Slots (9am-6pm) for weekdays
meeting_slots =
  for hour <- 9..17 do
    start_time = Time.new!(hour, 0, 0)
    end_time = Time.new!(hour + 1, 0, 0)

    %{
      name: "#{hour}:00 - #{hour + 1}:00",
      start_time: start_time,
      end_time: end_time
    }
  end

for day <- weekdays, slot <- meeting_slots do
  {:ok, _} =
    BookingSystem.TimeSlotTemplate
    |> Ash.Changeset.for_create(
      :create,
      slot |> Map.put(:space_id, meeting.id) |> Map.put(:day_of_week, day)
    )
    |> Ash.create()
end

IO.puts(
  "✓ Created #{length(weekdays) * length(meeting_slots)} meeting room hourly slots across weekdays"
)

# Create Music Studio Evening Slots for all days of the week
music_slots = [
  %{name: "Evening Session 1 (6pm-8pm)", start_time: ~T[18:00:00], end_time: ~T[20:00:00]},
  %{name: "Evening Session 2 (8pm-10pm)", start_time: ~T[20:00:00], end_time: ~T[22:00:00]}
]

all_days = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

for day <- all_days, slot <- music_slots do
  {:ok, _} =
    BookingSystem.TimeSlotTemplate
    |> Ash.Changeset.for_create(
      :create,
      slot |> Map.put(:space_id, music.id) |> Map.put(:day_of_week, day)
    )
    |> Ash.create()
end

IO.puts(
  "✓ Created #{length(all_days) * length(music_slots)} music studio evening slots across all days"
)

IO.puts("\n🎉 Seeding complete!")
