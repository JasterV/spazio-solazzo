This refactoring plan aims to consolidate the core booking logic into a single, highly reusable **Asset Booking LiveView**, while maintaining unique landing pages for the different space types (Meeting Room, Music Room, and Cowing).

By centralizing the date selection, time slot logic, and form submission, we eliminate the triplication of features and ensure that future updates (like phone number validation or hashing codes) only need to be implemented once.

---

# 🏗️ Refactoring Plan: Unified Asset Booking System

## Phase 1: Data Layer & Routing (The Ash Way)

Ensure the `Asset` and `Booking` resources are ready for a generic approach where an `Asset` is the central pivot.

1. **Route Definition**:
* Create a generic route: `/book/asset/:asset_id`.
* Keep the space-specific landing pages: `/meeting-room`, `/music-room`, `/coworking`.


2. **Generic Data Fetching**:
* Ensure the `Asset` resource has a `belongs_to :space` relationship.
* The generic LiveView will use the `asset_id` from the URL to fetch the `Asset` and preload its parent `Space` (to display the name).

## Phase 2: The Unified Asset Booking LiveView

Create `SpazioSolazzoWeb.BookingLive.AssetBooking`: a single LiveView that handles the 4-step booking journey.

1. **Step 1: Contextual Setup**:
* Mount the view using the `asset_id`.
* Load the `Asset` and its `Space` metadata using Ash.


2. **Step 2: Availability Logic**:
* Implement the date picker.
* On date selection, query `TimeSlotTemplate` filtered by `day_of_week` (as an atom) and `space_id`.


3. **Step 3: Verification Flow**:
* Integrate the existing `EmailVerification` resource flow (hashing the code, Oban cleanup, etc.).


4. **Step 4: Booking Finalization**:
* Use the `Booking.create` action.
* Ensure all new fields (`customer_phone`, `customer_comment`) are handled.



## Phase 3: Space Landing Pages (Personalization)

Update the three existing LiveViews to act as entry points rather than booking engines.

1. **Meeting & Music Rooms**:
* Replace the booking calendar with a high-quality image and description.
* Since these spaces effectively *are* the asset, add a "Book This Room" button that redirects to `/book/asset/[room_asset_id]`.


2. **Coworking Space**:
* Display space description and image.
* Include a selection component (e.g., a grid of tables).
* Each table choice must link to `/book/asset/[table_asset_id]`.


## Phase 4: Testing Suite (High Priority)
The testing strategy must be completely overhauled to reflect the new architecture.

## 4.1. New Asset Booking Flow Tests

Create a comprehensive test suite in test/spazio_solazzo_web/live/asset_booking_live_test.exs. This suite must cover the entire end-to-end flow and all edge cases:

Happy Path: Date selection -> Time selection -> Valid OTP entry -> Successful :reserved booking.

Validation Failures: Invalid phone formats, missing required fields, and invalid/expired OTP codes.

Concurrency/Edge Cases: Attempting to book a slot that was just taken by another user (handling Ash validation errors).

OTP Expiration: Verifying the UI correctly handles the case where the Oban worker has deleted the verification record after 60 seconds.

## 4.2. Space Landing Page Tests

Update the tests for MeetingRoomLive, MusicRoomLive, and CoworkingLive:

Verify the landing page renders correctly (description and images).

Strict Requirement: Verify that clicking the "Book" button or "Asset" link correctly redirects to the generic Asset Booking LiveView with the expected asset_id.

## 4.3. Ash Resource Tests

Ensure the `Booking` state machine and `EmailVerification` hashing tests are still passing independently of the UI.
