
Here is the updated project plan for **Spazio Solazzo**, optimized to use Ash command-line generators (`igniter`) to automate the boilerplate code creation.

````markdown
# Project Plan: Spazio Solazzo

**Target Stack:** Phoenix v1.8, Ash Framework, AshPostgres, Tailwind CSS v4.
**Goal:** A booking system for Musicians, Meeting Rooms, and Coworking spaces using a "Fixed Slot" availability model.

---

## 1. Project Setup
* **App Name:** Spazio Solazzo
* **Mix Project:** `spazio_solazzo`
* **Module Namespace:** `SpazioSolazzo`

---

## 2. Domain Architecture & Generation

We will use `mix ash.gen.*` tasks to scaffold the entire domain layer without writing manual boilerplate.

### A. Generators Command Reference
Run these commands in order to build the `BookingSystem` domain.

**1. Create the Domain:**
```bash
mix ash.gen.domain SpazioSolazzo.BookingSystem
````

**2. Generate Resources:**
Use the `--uuid-primary-key` flag (standard for Ash) and `--extend postgres` to auto-configure the data layer.

```bash
# Reference Data: Spaces (Musicians, Meeting, Coworking)
mix ash.gen.resource SpazioSolazzo.BookingSystem.Space \
  --uuid-primary-key \
  --extend postgres \
  --attribute "name:string" \
  --attribute "slug:string"

# Physical Assets (Tables, Rooms)
mix ash.gen.resource SpazioSolazzo.BookingSystem.Asset \
  --uuid-primary-key \
  --extend postgres \
  --attribute "name:string" \
  --relationship "belongs_to:space:SpazioSolazzo.BookingSystem.Space"

# Time Configuration (The Menu)
mix ash.gen.resource SpazioSolazzo.BookingSystem.TimeSlotTemplate \
  --uuid-primary-key \
  --extend postgres \
  --attribute "name:string" \
  --attribute "start_time:time" \
  --attribute "end_time:time" \
  --relationship "belongs_to:space:SpazioSolazzo.BookingSystem.Space"

# The Transaction (Booking)
mix ash.gen.resource SpazioSolazzo.BookingSystem.Booking \
  --uuid-primary-key \
  --extend postgres \
  --attribute "date:date" \
  --attribute "customer_name:string" \
  --attribute "customer_email:string" \
  --attribute "start_time:time" \
  --attribute "end_time:time" \
  --relationship "belongs_to:asset:SpazioSolazzo.BookingSystem.Asset" \
  --relationship "belongs_to:time_slot_template:SpazioSolazzo.BookingSystem.TimeSlotTemplate"
```

-----

## 3\. Business Logic Implementation

After generation, open `lib/spazio_solazzo/booking_system/resources/booking.ex` and manually add the specific action logic (this part cannot be generated yet).

```elixir
actions do
  create :create do
    # 1. API Contract
    argument :time_slot_template_id, :uuid, allow_nil?: false
    argument :asset_id, :uuid, allow_nil?: false
    argument :date, :date, allow_nil?: false
    argument :customer_name, :string, allow_nil?: false
    argument :customer_email, :string, allow_nil?: false

    # 2. Relationship Management
    change manage_relationship(:time_slot_template_id, :time_slot_template, type: :append_and_remove)
    change manage_relationship(:asset_id, :asset, type: :append_and_remove)

    # 3. Hydrate Times (Custom Logic)
    change fn changeset, _ctx ->
      template_id = Ash.Changeset.get_argument(changeset, :time_slot_template_id)
      template = SpazioSolazzo.BookingSystem.TimeSlotTemplate.get!(template_id)

      changeset
      |> Ash.Changeset.force_change_attribute(:start_time, template.start_time)
      |> Ash.Changeset.force_change_attribute(:end_time, template.end_time)
    end
  end
end
```

-----

## 4\. Database Constraints (Crucial)

**The Workflow:**

1.  Run the codegen task to create the migration file based on the resources we just generated:
    ```bash
    mix ash.codegen initial_setup
    ```
2.  **MANUAL STEP:** Open the generated migration file (in `priv/repo/migrations/`).
3.  Replace the `up` function for the `bookings` table creation with the **Exclusion Constraint** logic:

<!-- end list -->

```elixir
def up do
  execute("CREATE EXTENSION IF NOT EXISTS btree_gist")

  # ... existing table creation code ...

  execute """
  ALTER TABLE bookings
  ADD CONSTRAINT no_double_booking
  EXCLUDE USING GIST (
    asset_id WITH =,
    date WITH =,
    tsrange(start_time, end_time) WITH &&
  );
  """
end
```

4.  Run `mix ash.migrate`.

-----

## 5\. UI Generation (AshPhoenix)

We will use `mix ash_phoenix.gen.live` to scaffold the LiveViews. This gives us a working form, URL handling, and validation logic out of the box.

### A. Generate the Booking Flow

We generate a LiveView for creating bookings. Since this is a public form, we disable the actor checks for now (or set it to generic).

```bash
mix ash_phoenix.gen.live SpazioSolazzo.BookingSystem.Booking \
  --domain SpazioSolazzo.BookingSystem \
  --live-view SpazioSolazzoWeb.BookingLive \
  --uri /bookings \
  --no-actor
```

**What this gives you:**

  * `Index`, `Show`, and `FormComponent` LiveViews.
  * Automatic handling of `to_form`.
  * Error message display.

### B. Customization (The "Spazio Solazzo" Grid)

The generator creates a standard table/list view. You will update `booking_live/index.html.heex` to implement the specific UI needs:

1.  **Coworking:** Replace the standard table with a Map/Grid of tables.
2.  **Meeting/Music:** Replace the list with a Calendar/Grid of time slots.
3.  **Availability:** Use the generated `form_component` but wrap it in the logic that disables buttons based on availability.

-----

## 6\. Testing Strategy (Validation)

Validate every stage.

### A. Testing the Domain (Ash)

**File:** `test/spazio_solazzo/booking_system/booking_test.exs`

  * **Test Case 1 (Success):** Create a booking with valid template/date. Assert it returns `{:ok, booking}`.
  * **Test Case 2 (Constraint):**
    1.  Create a "Full Day" booking.
    2.  Attempt to create a "Morning" booking for the same asset/date.
    3.  Assert `{:error, _}` is returned (verifying the Postgres Exclusion Constraint).

### B. Testing the UI (LiveView)

**File:** `test/spazio_solazzo_web/live/booking_live_test.exs`

  * **Test Case 1:** Render the page, assert `TimeSlotTemplate` buttons are visible.
  * **Test Case 2:** Select a date with an existing booking. Assert the overlapping button has the `disabled` attribute.

-----

## 7\. Development Roadmap

### Phase 1: Foundation

1.  **Init:** `mix phx.new spazio_solazzo --no-ecto`.
2.  **Deps:** Add `ash`, `ash_phoenix`, `ash_postgres`, `igniter`.
3.  **Install:** `mix igniter.install ash_postgres`.

### Phase 2: Domain Generation

Run the `mix ash.gen.*` commands from **Section 2**.

### Phase 3: Database & Logic

1.  Update `booking.ex` with the `create` action logic.
2.  Run `mix ash.codegen`.
3.  **Edit the migration** (Section 4).
4.  Run `mix ash.migrate`.

### Phase 4: Seeding

Create `priv/repo/seeds.exs`:

  * **Coworking:** "Morning" (09-13), "Afternoon" (14-18), "Full Day" (09-18).
  * **Music:** Evening slots.
  * **Meeting:** Hourly slots.

### Phase 5: Frontend

1.  Run `mix ash_phoenix.gen.live` (Section 5).
2.  Refactor the generated `index.html.heex` to show the Space-specific Grids instead of a raw list of bookings.
3.  Implement `slot_available?` logic in the LiveView.

### Phase 6: Final Verification

1.  Run `mix test`.
