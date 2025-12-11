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
coworking =
  BookingSystem.create_space!("Coworking", "coworking", "Flexible desk spaces for remote work")

IO.puts("✓ Created Coworking space")

# Create Meeting Room Space
meeting =
  BookingSystem.create_space!("Meeting room", "meeting", "Private conference rooms by the hour")

IO.puts("✓ Created Meeting Room space")

# Create Music Studio Space
music = BookingSystem.create_space!("Music room", "music", "Evening recording sessions")

IO.puts("✓ Created Music Studio space")

# Create Coworking Tables (Assets)
tables =
  for i <- 1..5 do
    BookingSystem.create_asset!("Table #{i}", coworking.id)
  end

IO.puts("✓ Created #{length(tables)} coworking tables")

# Create Meeting Room Asset
BookingSystem.create_asset!("Main Conference Room", meeting.id)

IO.puts("✓ Created meeting room asset")

# Create Music Studio Asset
BookingSystem.create_asset!("Recording Studio", music.id)

IO.puts("✓ Created music studio asset")

# Create Coworking Time Slot Templates for each weekday
coworking_slots = [
  %{start_time: ~T[09:00:00], end_time: ~T[13:00:00]},
  %{start_time: ~T[14:00:00], end_time: ~T[18:00:00]}
]

weekdays = [:monday, :tuesday, :wednesday, :thursday, :friday]

for day <- weekdays, slot <- coworking_slots do
  BookingSystem.create_time_slot_template!(slot.start_time, slot.end_time, day, coworking.id)
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
      start_time: start_time,
      end_time: end_time
    }
  end

for day <- weekdays, slot <- meeting_slots do
  BookingSystem.create_time_slot_template!(slot.start_time, slot.end_time, day, meeting.id)
end

IO.puts(
  "✓ Created #{length(weekdays) * length(meeting_slots)} meeting room hourly slots across weekdays"
)

# Create Music Studio Evening Slots for all days of the week
music_slots = [
  %{start_time: ~T[18:00:00], end_time: ~T[20:00:00]},
  %{start_time: ~T[20:00:00], end_time: ~T[22:00:00]}
]

all_days = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

for day <- all_days, slot <- music_slots do
  BookingSystem.create_time_slot_template!(slot.start_time, slot.end_time, day, music.id)
end

IO.puts(
  "✓ Created #{length(all_days) * length(music_slots)} music studio evening slots across all days"
)

IO.puts("\n🎉 Seeding complete!")
