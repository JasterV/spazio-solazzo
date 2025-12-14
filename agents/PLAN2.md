# 📋 Implementation Plan: Secure Booking System & Admin Backoffice

This document outlines the requirements for extending the booking application. All features must be implemented following **Ash Framework** patterns, leveraging resources, actions, extensions, and standard tooling (`AshAuthentication`, `AshStateMachine`, `AshPhoenix`).

## 1. Administrator Authentication
**Goal:** Implement a secure, passwordless entry for system administrators.

* **Tooling:** Use `ash_authentication` and `ash_authentication_phoenix`.
* **Resource Requirement:** Create a new `Admin` resource.
    * It must use the `magic_link` authentication strategy.
    * It must **not** allow public registration (sign-up actions should be disabled or protected).
    * Identity field: `email`.
* **Seeding:** Since registration is disabled, creating administrators must be done via a database seed script. Ensure there is a way to insert trusted emails into the `Admin` table.
* **Session Management:**
    * Configure a Phoenix plug pipeline to load the user from the session.
    * Create a dedicated Phoenix `live_session` (e.g., `:admin_dashboard`) that strictly enforces authentication. Unauthenticated users attempting to access this scope must be redirected to the sign-in page.

## 2. Weekly Availability Configuration
**Goal:** Allow time slots to be defined for specific days of the week rather than just generic dates.

* **Data Model Update:**
    * Modify the `TimeSlotTemplate` resource to include a `day_of_week` attribute.
    * **Requirement:** This attribute must be an **Atom** (not an integer).
    * **Validation:** Use Ash constraints to strictly limit values to valid days (e.g., `[:monday, :tuesday, ... :sunday]`).
    * **Overlap Logic:** Update the existing overlap validation logic. It must now consider the `day_of_week`. A slot at 9:00 AM on Monday should *not* conflict with a slot at 9:00 AM on Tuesday.
* **LiveView Requirement:**
    * Update the public booking calendar. When a user selects a specific date (e.g., Oct 27th), the system must determine the day of the week (e.g., `:friday`) and query `TimeSlotTemplate` using that atom to show relevant availability.

## 3. Booking Flow: State Machine & OTP Verification
**Goal:** Validate user intent via email code before confirming a booking, and manage the booking lifecycle using a formal State Machine.

### 3.1. Infrastructure
* **Tooling:** Use `ash_state_machine` for the booking lifecycle and `oban` for background cleanup.
* **New Resource (`BookingVerification`):**
    * Create a resource to hold the ephemeral OTP data.
    * **Attributes:** `code` (string), `expires_at` (datetime), and a relationship to the `Booking`.
    * **Lifecycle:** This record should be created immediately when a user attempts a booking and deleted upon successful verification or expiration.

### 3.2. Booking Resource Updates
* **State Machine:** Implement `AshStateMachine` on the `Booking` resource with the following states and transitions:
    * **`pending_verification`**: Initial state. User has submitted the form but not the code.
    * **`reserved`**: User has verified their email. The slot is held.
    * **`completed`**: Customer arrived and paid (Admin action).
    * **`cancelled`**: Booking was cancelled (Admin action).
* **Actions:**
    * **Create Action:** Accepts booking details -> transitions to `pending_verification`.
        * *Side Effect:* Must trigger the creation of a `BookingVerification` record.
        * *Side Effect:* Must enqueue an **Oban** job scheduled to run in **61 seconds**.
    * **Confirm Email Action:** Accepts the OTP code -> transitions to `reserved`.
        * *Validation:* Must check the code against the `BookingVerification` resource and ensure it hasn't expired.
        * *Side Effect:* Must **delete** the `BookingVerification` record upon success.
    * **Admin Actions:** Add actions for `confirm_payment` (`reserved` -> `completed`) and `cancel` (`reserved` -> `cancelled`).

### 3.3. Background Cleanup (Oban)
* **Worker:** Implement an Oban worker that accepts a `verification_id`.
* **Logic:** When the job runs, it attempts to fetch and delete the `BookingVerification` record. If the user has already verified (and thus the record is already gone), the job should simply complete without error.

### 3.4. User Interface
* **Flow:**
    1.  User fills booking form.
    2.  System sends email and swaps UI to "Enter Code" view with a 60s countdown.
    3.  User enters code.
    4.  System transitions booking to `reserved` and shows success message.
* **Timeout:** If the user fails to enter the code in time, the Oban job cleans up the verification record, effectively invalidating the attempt.



## 4. Backoffice Platform
**Goal:** A protected administrative interface for managing the business.

* **Layout:** Create a generic `Backoffice` layout accessible only to logged-in admins.

### 4.1. Booking Management Page
* **Tabbed Navigation:** The page must fetch all active `Space` resources and display them as **Tabs** at the top of the view.
    * *Behavior:* Clicking a tab filters the booking list to show only bookings associated with that specific Space.
* **List View:** Display a paginated list of bookings for the selected Space.
    * *Default Filter:* Show only `reserved` bookings (active tasks).
    * *Search:* Use `AshPhoenix.FilterForm` to allow filtering by customer name, email, and date within the selected Space.
* **Management:**
    * Provide UI controls to trigger the `confirm_payment` (Check-in) and `cancel` actions defined in the Booking state machine.
    * Visually distinguish the status of bookings (e.g., Badges for Reserved vs. Completed).

### 4.2. Availability Configuration Page
* **Tabbed Navigation:** Similar to the booking page, display all `Space` resources as **Tabs**.
    * *Behavior:* Clicking a tab loads the `TimeSlotTemplate` configuration specifically for that Space.
* **UI:** Implement a weekly calendar grid (Columns = Days, Rows = Time).
* **Data Fetching:** Query `TimeSlotTemplates` for the *selected Space* and group them by `day_of_week` in the LiveView logic.
* **Interaction:**
    * Allow Admins to click a specific day/time area to add a slot.
    * The "Add" form must automatically apply the correct `day_of_week` atom based on the column clicked and associate it with the active Space tab.
    * Allow editing and deleting of existing slots.

## 5. Quality Assurance (Testing)
**Goal:** Ensure reliability using standard Phoenix & Ash testing tools.

* **Unit Tests:**
    * **Validation:** Verify that `TimeSlotTemplate` rejects invalid day atoms and correctly prevents overlapping slots for the same day.
    * **State Machine:** Test valid and invalid transitions (e.g., ensure a `pending` booking cannot jump straight to `completed`).
    * **Logic:** Precise test that the `BookingVerification` logic works (code matching, expiration checks).
* **Integration Tests:**
    * **Auth:** Verify the Magic Link flow allows login and sets the correct session.
    * **Booking:** Simulate the full user journey: Form Submission -> Mock Email Receipt -> Code Entry -> Confirmation.
    * **Backoffice:** Verify that Admins can toggle between Space tabs and that data is correctly filtered for each Space.
