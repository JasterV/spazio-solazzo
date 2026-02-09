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

# Create Coworking Space (capacity: 10)
coworking =
  BookingSystem.create_space!(
    "Arcipelago",
    "arcipelago",
    "Flexible desk spaces for remote work",
    6
  )

IO.puts("✓ Created Coworking space")

# Create Meeting Room Space (capacity: 1)
meeting =
  BookingSystem.create_space!(
    "Media room",
    "media-room",
    "Private conference room for your meetings",
    1
  )

IO.puts("✓ Created Meeting Room space")

# Create Music Studio Space (capacity: 1)
music =
  BookingSystem.create_space!(
    "Hall",
    "hall",
    "Tailored for band rehearsals.",
    1
  )

IO.puts("✓ Created Music Studio space")

# Create Coworking Time Slot Templates for each weekday
coworking_slots = [
  %{start_time: ~T[10:00:00], end_time: ~T[14:00:00]},
  %{start_time: ~T[14:00:00], end_time: ~T[18:00:00]}
]

for day <- [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday],
    slot <- coworking_slots do
  BookingSystem.create_time_slot_template!(slot.start_time, slot.end_time, day, coworking.id)
end

IO.puts("✓ Created coworking time slots across weekdays")

for day <- [:monday, :tuesday, :thursday, :friday, :saturday], hour <- 10..17 do
  start_time = Time.new!(hour, 0, 0)
  end_time = Time.new!(hour + 1, 0, 0)

  BookingSystem.create_time_slot_template!(start_time, end_time, day, meeting.id)
end

IO.puts(
  "✓ Created meeting room hourly slots across for monday, tuesday, thursday, friday and saturday"
)

for day <- [:wednesday, :sunday], hour <- 14..17 do
  start_time = Time.new!(hour, 0, 0)
  end_time = Time.new!(hour + 1, 0, 0)
  BookingSystem.create_time_slot_template!(start_time, end_time, day, meeting.id)
end

IO.puts("✓ Created meeting room hourly slots across for wednesday and sunday")

for day <- [:monday, :wednesday, :thursday, :friday, :saturday, :sunday] do
  BookingSystem.create_time_slot_template!(~T[18:00:00], ~T[21:00:00], day, music.id)
end

for day <- [:wednesday, :sunday] do
  BookingSystem.create_time_slot_template!(~T[11:00:00], ~T[14:00:00], day, music.id)
end

IO.puts("✓ Created music studio evening slots across the week")

IO.puts("\n🎉 Seeding complete!")
