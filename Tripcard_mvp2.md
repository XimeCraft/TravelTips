# TripCard MVP2 — Requirements Document

**Reference Design:** `TravelPlanner_mvp2.jsx` (React prototype with all UI, interactions, and visual style)
**Builds on:** MVP1 (`TripCard-PRD.md`)

---

## MVP2 Scope Summary

MVP2 adds **CRUD operations**, **redesigned Day Detail** (swipeable timeline cards), **color-coded type system**, **linked item previews**, and **"View details" entry points** across all tabs.

---

## What's New in MVP2

### 1. CRUD Operations (All Tabs)

Every content tab has a **green "+" button** (top-right corner, SF Symbol `plus`) that opens a **half-screen sheet** (iOS `.sheet` presentation) with a form.

| Tab | Sheet Title | Fields |
|-----|------------|--------|
| Trips (home) | "New Trip" | Trip Name, Emoji, Start Date, End Date |
| Transport | "Add Transport" | Day (picker), Type (flight/drive/train/bus), From, To, Dep. Time, Arr. Time, Detail |
| Hotels | "Add Hotel" | Hotel Name, Address, Check-in Date, Check-out Date |
| Places | "Add Place" | Day (picker), Name, Type (attraction/restaurant/activity), Address, Time, Ticket Price, Notes |
| Info | "Add Info Item" | Title, Details |
| Day Detail | "Add Timeline Item" | Time, Title, Type, Notes |

**Sheet behavior:**
- Half-screen modal with drag-to-dismiss
- "Cancel" button (top-right) and "Save" button (bottom, green `#076C44`)
- Form fields are design-only placeholders in the prototype; actual input handled in SwiftUI

**Delete:** Left-swipe on any card to reveal delete action (SwiftUI `.swipeActions`).

**Edit:** Tap any card to open the same sheet form pre-filled with existing data.

### 2. Trip Creation Flow

**Step 1:** Tap "+" on Trips tab → "New Trip" sheet with minimal fields (name, emoji, start/end dates)
**Step 2:** On save, auto-generate empty `TripDay` objects for each date in range
**Step 3:** User fills content incrementally via each tab (Transport, Hotels, Places, etc.)

### 3. Day Detail — Redesigned

The Day Detail view is completely redesigned from MVP1's horizontal paging cards to a **swipeable day card with vertical timeline**.

**Navigation:** Horizontal swipe between days (scroll snap), with dot indicators at bottom showing current day position. Tapping a dot jumps to that day.

**Day Card Structure (each day = one large card, 340px wide):**

```
┌─────────────────────────────────────┐
│ ☐ Mark day as done          3/6     │  ← Full-day checkbox + progress
├─────────────────────────────────────┤
│ ▌ 06:30  ✈️                         │  ← Color bar + time badge + icon
│ ▌ Arrive Cairo Airport T2           │  ← Title
│ ▌ Visa → SIM → Currency             │  ← Note
│ ▌ ┌─ Chengdu TFU → Cairo CAI ─┐    │  ← Linked transport preview
│ ▌ │  01:40 → 06:30 · 3U3863   │    │
│ ▌ │  📅 Thu, Mar 12            │    │
│ ▌ └────────────────────────────┘    │
│ ▌ View details ›                    │  ← Every item has this
├─────────────────────────────────────┤
│ ▌ 09:00  🏨                         │
│ ▌ Check-in Ramses Hilton            │
│ ▌ ...                               │
└─────────────────────────────────────┘
```

**Full-day completion checkbox:**
- Top of each day card: "Mark day as done" with checkbox
- Shows progress counter (e.g., "3/6")
- Toggling sets ALL timeline items' `done` state simultaneously
- Visual: background changes to green tint when completed

**Timeline items:**
- 4px left color bar (type-coded)
- Time badge (colored background) + type emoji icon
- Title (strikethrough when done)
- Optional note text
- Optional linked item preview (colored background box)
- "View details ›" link on every item (uses type color)
- Checkbox per item (uses type color)
- Done items: opacity 0.4, strikethrough title

### 4. Color-Coded Type System

Consistent across Overview tags, Day Detail timeline bars, and all "View details" buttons:

| Type | Color | Hex | Icon | Used For |
|------|-------|-----|------|----------|
| Transport | Blue | `#2196F3` | ✈️🚗🚄🚌 | Flights, drives, trains, buses |
| Hotel | Purple | `#9C27B0` | 🏨 | Check-in, check-out, hotel stays |
| Place/Attraction | Yellow | `#F9A825` | 🏛️ | Temples, museums, landmarks |
| Meals | Green | `#076C44` | 🍽️ | Lunch, dinner, restaurants |
| Activity | Cyan | `#00BCD4` | 🎪 | Hot air balloon, snorkeling, tours |
| Other | Gray | `#9E9E9E` | 📝 | General items, packing, rest |

**Color consistency rules:**
- Transport tab: type pill always blue (`#2196F3`), "View details" button blue
- Hotels tab: night count pill purple, "View details" button purple
- Places tab: ticket price pill yellow, "View details" button uses item's type color (yellow for attractions, cyan for activities)
- Info tab: "View details" button green (`#076C44`), button style (not inline text)
- Overview tab tags: transport = blue with icon, check-in = purple with 🏨, places = yellow with 📍
- Day Detail: left color bar, time badge background, checkbox color, "View details" text — all match item type

### 5. Linked Item Previews (Day Detail)

Timeline items with a `linkedId` show an inline preview box below the note:

| Link Type | Preview Content | Background |
|-----------|----------------|------------|
| Transport (flight/drive) | `from → to`, `depTime → arrTime · detail`, `📅 date` | Blue 8% |
| Hotel | Hotel name, `📍 address` | Purple 8% |
| Attraction/Activity | Destination name, `📍 address · ticketPrice` | Type color 8% |

Preview lookup is **cross-day** — a timeline item on Day 6 can link to a hotel from Day 5.

### 6. "View details ›" Entry Points

Every card and timeline item now has a "View details ›" link. In MVP2 this is a **placeholder** (tappable but navigates nowhere). MVP3 will implement actual detail pages with attachments.

| Location | Button Style | Color |
|----------|-------------|-------|
| Transport tab cards | Centered button with background | Blue |
| Hotels tab cards | Centered button with background | Purple |
| Places tab cards | Centered button with background | Type color |
| Info tab items | Centered button with background | Green |
| Day Detail timeline items | Inline text link | Type color |

### 7. Overview Tab Enhancements

- **Days count highlight:** "12 days" shown with green background pill (`#076C44` at 18% opacity)
- **Tag icons:** Transport pill includes type emoji (✈️/🚗), Check-in includes 🏨, Places includes 📍
- **Tag colors:** Transport = blue, Check-in = purple, Places = yellow (matching the type system)
- **City name bold:** Right-aligned city text is now `fontWeight: 600`, color: `#1A1A1A`

### 8. Trip Card (Home Screen)

- Date range and days count on **separate lines** (not one line)
- Line 1: `Thu, Mar 12 – Mon, Mar 23`
- Line 2: `12 days`

---

## Updated Data Models

Changes from MVP1 are marked with `// NEW` or `// CHANGED`:

```
Trip
├── id: UUID
├── name: String
├── emoji: String
├── startDate: Date
├── endDate: Date
├── color: String
├── infoItems: [InfoItem]
└── days: [TripDay]

TripDay
├── id: UUID
├── date: Date
├── city: String
├── summary: String
├── transports: [Transport]         // CHANGED: array (was single optional)
├── accommodation: Accommodation?
├── destinations: [Destination]
├── dayDone: Bool                   // NEW: full-day completion state
└── timeline: [TimelineItem]        // CHANGED: renamed from DayDetail

Transport
├── id: UUID                        // NEW: needed for linkedId references
├── type: TransportType
├── detail: String
├── from: String
├── to: String
├── departureTime: String
└── arrivalTime: String

Accommodation
├── id: UUID                        // NEW: needed for linkedId references
├── name: String
├── address: String
├── isCheckIn: Bool
└── isCheckOut: Bool

Destination
├── id: UUID                        // NEW: needed for linkedId references
├── name: String
├── type: DestinationType
├── time: String?
├── address: String
├── ticketPrice: String?
└── notes: String?

TimelineItem                        // CHANGED: renamed from DayDetail
├── id: UUID
├── time: String
├── title: String
├── note: String?
├── type: TimelineType              // NEW: enum for color coding
├── linkedId: UUID?                 // NEW: reference to transport/accommodation/destination
├── isDone: Bool
└── sortOrder: Int

InfoItem
├── id: UUID
├── title: String
├── details: String
├── isDone: Bool
└── sortOrder: Int
```

**New Enums:**

```swift
enum TimelineType: String, Codable {
    case flight, drive, train, bus, ferry  // → transport color (blue)
    case hotel                             // → hotel color (purple)
    case attraction                        // → place color (yellow)
    case restaurant                        // → meal color (green)
    case activity                          // → activity color (cyan)
    case other                             // → gray
}
```

**LinkedId Resolution:**
Timeline items reference other objects by UUID. Lookup should search across ALL days in the trip (not just the current day), because:
- A check-out on Day 6 may link to a hotel that was checked into on Day 3
- Transport linking is straightforward (same day)

---

## UI Details & Interactions

### Swipeable Day Cards
- Horizontal `ScrollView` with `.scrollTargetBehavior(.paging)` or `TabView` with `.tabViewStyle(.page)`
- Each card 340pt wide, scroll snap to center
- Dot indicators below: active dot = elongated (20pt wide), inactive = circle (6pt)
- Tapping dots navigates to that day

### Full-Day Checkbox
- Tapping "Mark day as done" toggles `dayDone` and sets ALL `timeline[].isDone` to match
- Progress counter updates in real-time (e.g., "3/6" → "6/6")
- Individual item checkboxes still work independently
- If all items manually checked, `dayDone` should also become true

### Sheet Forms
- Use `.sheet(isPresented:)` with `presentationDetents([.medium])`
- All fields use standard SwiftUI form controls (`TextField`, `DatePicker`, `Picker`)
- "Save" validates required fields, creates SwiftData object, dismisses sheet
- "Cancel" dismisses without saving

### Swipe to Delete
- `.swipeActions(edge: .trailing)` with red delete button
- Confirmation alert before permanent deletion
- Works on: trip cards, transport cards, hotel cards, destination cards, info items, timeline items

### Tab-Level "+" Button
- Position: top-right corner, overlaying content
- Style: 30×30pt green circle with white "+" 
- Always visible (fixed position, not scrolling with content)

---

## What's NOT Included (MVP3)

- ❌ Attachment system (images, PDFs for e-tickets, confirmations, etc.)
- ❌ Detail pages (currently "View details ›" is placeholder — will navigate to full detail view)
- ❌ Full-screen image/PDF preview
- ❌ Sharing attachments
- ❌ iCloud sync
- ❌ Search functionality
- ❌ Reminders tab real functionality (still placeholder)
- ❌ Settings functionality (still placeholder)

---

## Migration Notes (MVP1 → MVP2)

1. **Data model migration:** `transport: Transport?` → `transports: [Transport]`. Wrap existing single transport in array.
2. **DayDetail → TimelineItem:** Add `type` and `linkedId` fields. Existing items get `type: .other` and `linkedId: nil`.
3. **Add IDs:** Ensure `Transport`, `Accommodation`, and `Destination` all have `id: UUID` for linking.
4. **Add `dayDone`:** New boolean on `TripDay`, default `false`.
5. **Seed data update:** The Egypt trip seed data now includes `transports[]`, `timeline[]` with types and linkedIds, and `dayDone`. See the React prototype for complete seed data structure.

---

## Implementation Priority

1. **Data model updates** — Update SwiftData models first (Transport array, TimelineItem, IDs, linkedId)
2. **Day Detail redesign** — Swipeable cards with timeline, color bars, checkboxes
3. **CRUD sheets** — "+" button and sheet forms for each tab
4. **Color system** — Apply consistent type colors across Overview, Day Detail, and all tabs
5. **Linked previews** — Cross-day lookup and inline preview rendering
6. **View details buttons** — Add placeholder buttons to all cards
7. **Swipe to delete** — Add swipe actions on all card types
8. **Polish** — Overview enhancements (bold city, green days highlight, tag icons/colors)
