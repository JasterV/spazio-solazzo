# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias SpazioSolazzo.BookingSystem

IO.puts("Seeding Spazio Solazzo booking system...")

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

# Create Coworking Time Slot Templates
coworking_slots = [
  %{name: "Morning (9am-1pm)", start_time: ~T[09:00:00], end_time: ~T[13:00:00]},
  %{name: "Afternoon (2pm-6pm)", start_time: ~T[14:00:00], end_time: ~T[18:00:00]},
  %{name: "Full Day (9am-6pm)", start_time: ~T[09:00:00], end_time: ~T[18:00:00]}
]

for slot <- coworking_slots do
  {:ok, _} =
    BookingSystem.TimeSlotTemplate
    |> Ash.Changeset.for_create(:create, Map.put(slot, :space_id, coworking.id))
    |> Ash.create()
end

IO.puts("✓ Created #{length(coworking_slots)} coworking time slots")

# Create Meeting Room Hourly Slots (9am-6pm)
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

for slot <- meeting_slots do
  {:ok, _} =
    BookingSystem.TimeSlotTemplate
    |> Ash.Changeset.for_create(:create, Map.put(slot, :space_id, meeting.id))
    |> Ash.create()
end

IO.puts("✓ Created #{length(meeting_slots)} meeting room hourly slots")

# Create Music Studio Evening Slots
music_slots = [
  %{name: "Evening Session 1 (6pm-8pm)", start_time: ~T[18:00:00], end_time: ~T[20:00:00]},
  %{name: "Evening Session 2 (8pm-10pm)", start_time: ~T[20:00:00], end_time: ~T[22:00:00]},
  %{name: "Full Evening (6pm-10pm)", start_time: ~T[18:00:00], end_time: ~T[22:00:00]}
]

for slot <- music_slots do
  {:ok, _} =
    BookingSystem.TimeSlotTemplate
    |> Ash.Changeset.for_create(:create, Map.put(slot, :space_id, music.id))
    |> Ash.create()
end

IO.puts("✓ Created #{length(music_slots)} music studio evening slots")

IO.puts("\n🎉 Seeding complete!")
