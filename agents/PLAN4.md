This plan is designed to guide an AI agent through a visual overhaul of the **Spazio Solazzo** platform. The objective is to transition from a generic UI to a Mediterranean-inspired, vibrant, and modern aesthetic that reflects the warmth of Palermo and the presence of the sun.

---

# 🎨 Visual Overhaul Plan: The "Sun & Earth" Aesthetic

## 1. Objective

Transform the UI into a warm, "earthy," and modern experience. The design should feel organic and sun-drenched, using the location (Palermo, Sicily) as the primary inspiration.

## 2. Phase 1: Color Palette Definition (Tailwind Config)

Update `tailwind.config.js` with a custom theme. Avoid generic "gray" or "blue."

* **Primary (The Sun):** Vibrant golden yellow (`#F59E0B`) and burnt orange (`#D97706`). Use these for primary actions and highlights.
* **Secondary (The Earth):** Terracotta (`#9F1239` or `#B45309`), Sage Green (`#4D7C0F`), and Warm Clay (`#A8A29E`).
* **Backgrounds:** Instead of pure white, use "Paper" or "Sand" whites (`#FAF9F6` or `#FFFBEB`).
* **Sea Accents:** A deep Teal (`#0D9488`) for subtle contrast, representing the nearby Sicilian coast.

## 3. Phase 2: Global Styling & Typography

* **Typography:** * **Headings:** Use a warm, modern Serif (e.g., *Lora* or *Playfair Display*) to provide an "artisanal/earthy" Mediterranean feel.
* **Body:** Use a clean, highly readable Sans-Serif (e.g., *Inter* or *Montserrat*) for modern functionality.


* **Organic Shapes:** Replace sharp `rounded-md` with `rounded-2xl` or `rounded-3xl` to mimic the soft shapes found in nature and sun-washed architecture.
* **The Sun Motif:** * Implement a "Glow" effect: Use subtle amber gradients (`bg-gradient-to-br from-yellow-400 to-orange-500`) on key elements.
* Ensure the logo or header features a stylized sun icon as a central visual anchor.



## 4. Phase 3: Component-Specific Updates

Apply the theme to the existing Phoenix components:

* **Landing Pages (Spaces):**
* Use high-resolution imagery of the space with "warm" filters.
* Add a decorative "sun" background element (e.g., a large, semi-transparent amber circle behind the space description).


* **The Booking Form (OTP & Inputs):**
* **Buttons:** Must be vibrant "Sun" colors. Use `hover:scale-105` transitions to make them feel energetic.
* **Inputs:** Use the "Earth" palette for borders (Clay/Sand). Focus states should glow amber, not blue.


* **Verification Screen:** Use a warm, terracotta-colored progress bar for the 60-second countdown.

## 5. Phase 4: Unified Asset Booking View Styling

Since this is the "Engine" of the site, it must remain modern and easy to use while staying on-theme.

* **Calendar:** Replace the default blue selection with a "Golden/Amber" selection.
* **Time Slots:** Use Sage Green for "Available" and a soft Clay color for "Selected."
* **Cards/Containers:** Use white-smoke backgrounds with soft, warm shadows (`shadow-orange-100/50`) instead of harsh black shadows.

## 6. Phase 5: Implementation & Testing

1. **Tailwind Refactor:** Update the CSS classes in `core_components.ex` to use the new custom colors.
2. **Visual Consistency:** Ensure that the specific "Meeting Room," "Coworking," and "Music Room" landing pages use shared layout components to maintain a unified feel.
3. **Accessibility Check:** Ensure that white text on "Sun" (yellow) backgrounds has enough contrast (use darker orange/black for text on yellow).
