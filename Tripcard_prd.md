# TripCard — Travel Itinerary Planner

## Overview

An iOS app (SwiftUI, iOS 17+) for organizing and viewing pre-planned travel itineraries. The core problem: travelers have flight times, hotel addresses, attraction details, and to-do items scattered across booking sites, notes, and messages. This app consolidates everything into one clean, offline-accessible interface.

**Reference Design:** See the attached React prototype (`travel-planner-v2.jsx`) for exact UI layout, interactions, and visual style.

---

## Tech Stack

- **SwiftUI** (iOS 17 minimum)
- **SwiftData** for local persistence
- **SF Symbols** for all tab bar and UI icons
- **No backend / no network required** — everything is local

---

## Color Theme

- Primary: `#076C44` (green)
- Use lighter/darker variants for backgrounds, tags, accents
- App background: `#F4F5F2` (warm off-white)
- Cards: `#FFFFFF`
- Text primary: `#1A1A1A`, secondary: `#888888`

---

## Navigation Structure

### Level 1: App Root (3 tabs)

| Tab | Icon (SF Symbol) | Content |
|-----|------------------|---------|
| Trips | `house.fill` | List of all trips, + Add New Trip |
| Reminders | `bell.fill` | Cross-trip upcoming reminders/tasks |
| Settings | `gearshape.fill` | Language, notifications, backup, appearance, about |

### Level 2: Inside a Trip (5 tabs)

When user taps a trip, the bottom tab bar switches to trip-specific tabs:

| Tab | Icon (SF Symbol) | Content |
|-----|------------------|---------|
| Overview | `list.bullet.rectangle` | Daily summary cards, tap to see day detail |
| Transport | `airplane` | All transport entries across the trip |
| Hotels | `bed.double.fill` | Grouped hotel stays |
| Places | `mappin.and.ellipsis` | All destinations grouped by day |
| Info | `info.circle.fill` | Practical info checklist (visa, SIM, currency, etc.) |

A **back button** at top-left returns to the trip list.

### Level 3: Day Detail

Full-screen **horizontal paging cards** (one card per event/task). Each card shows:
- Time
- Title  
- Notes
- Checkbox (top-right) — mark as done
- Card counter (e.g., "3 / 6")

"Hide done" / "Show all" toggle at top-right.
Done cards become semi-transparent (opacity ~0.5) with strikethrough title, but are NOT removed unless user toggles "Hide done".

---

## Data Models (SwiftData)

```
Trip
├── id: UUID
├── name: String                    // "Egypt"
├── emoji: String                   // "🇪🇬"
├── startDate: Date
├── endDate: Date
├── color: String                   // hex string, default "#076C44"
├── infoItems: [InfoItem]           // practical info checklist
└── days: [TripDay]                 // ordered by date

TripDay
├── id: UUID
├── date: Date
├── city: String                    // "Cairo" or "Cairo → Luxor"
├── summary: String                 // one-line summary for overview
├── transport: Transport?           // optional, one per day
├── accommodation: Accommodation?   // optional
├── destinations: [Destination]     // 0 or more
└── details: [DayDetail]            // timeline cards for day detail view

Transport
├── id: UUID
├── type: TransportType             // enum: flight, drive, train, bus, ferry, other
├── detail: String                  // flight number or description, e.g. "3U3863"
├── from: String                    // "Chengdu TFU T1"
├── to: String                      // "Cairo CAI T2"
├── departureTime: String           // "01:40" (stored as string for display flexibility)
└── arrivalTime: String             // "06:30"

Accommodation
├── id: UUID
├── name: String                    // "Ramses Hilton"
├── address: String                 // full address for maps
├── isCheckIn: Bool                 // show "Check-in" tag
└── isCheckOut: Bool                // show "Check-out" tag

Destination
├── id: UUID
├── name: String                    // "GIZA Pyramids"
├── type: DestinationType           // enum: attraction, activity, restaurant, shopping, other
├── time: String?                   // "08:00-12:00"
├── address: String
├── ticketPrice: String?            // "540 EGP"
└── notes: String?                  // "Go early to avoid heat"

DayDetail
├── id: UUID
├── time: String                    // "06:30" or "All Day"
├── title: String                   // "Arrive Cairo Airport T2"
├── note: String?                   // additional details
├── isDone: Bool                    // checkbox state
└── sortOrder: Int                  // for manual ordering

InfoItem
├── id: UUID
├── title: String                   // "Visa on Arrival"
├── details: String                 // longer description
├── isDone: Bool
└── sortOrder: Int
```

---

## MVP1 Scope (Current)

### What's included:
1. ✅ Full read-only display of all screens (Overview, Transport, Hotels, Places, Info, Day Detail)
2. ✅ Checkbox interactions (mark done on InfoItems and DayDetails)
3. ✅ "Hide done / Show all" toggle on Day Detail
4. ✅ Navigation between all levels (trips → trip tabs → day detail → back)
5. ✅ SwiftData persistence (checkbox state survives app restart)
6. ✅ Pre-loaded Egypt trip data (hardcoded as seed data on first launch)
7. ✅ Hotel address "Copy" and "Open in Maps" buttons (functional)
8. ✅ Tab bar switches between app-level and trip-level tabs

### What's NOT included (MVP2):
- ❌ Add / Edit / Delete trips
- ❌ Add / Edit / Delete days, transport, hotels, destinations, details
- ❌ Reminders tab content (show placeholder)
- ❌ Settings functionality (show placeholder)
- ❌ Search
- ❌ Photo attachments
- ❌ iCloud sync

---

## Egypt Trip Seed Data

Pre-load this data on first app launch. All data comes from the user's actual itinerary:

### Day 1 — March 12, 2026 — Cairo
- **Transport:** Flight 3U3863, Chengdu TFU T1 → Cairo CAI T2, 01:40 → 06:30
- **Hotel:** Ramses Hilton, 1115 Corniche El Nil, Cairo (Check-in)
- **Places:** The Egyptian Museum in Cairo, Tahrir Square, 14:00-17:00, 450 EGP
- **Timeline:** Arrive airport → Transfer to hotel → Check-in & Rest → Egyptian Museum → Dinner

### Day 2 — March 13, 2026 — Cairo → Luxor
- **Transport:** Flight, Cairo → Luxor, 21:00 → 22:40
- **Hotel:** Sonesta St. George Hotel - Luxor (Check-in)
- **Places:** GIZA Pyramids (08:00-12:00, 540 EGP), Grand Egyptian Museum (13:00-17:00, 600 EGP)
- **Timeline:** Giza → Lunch → Grand Museum → Pack → Flight to Luxor

### Day 3 — March 14, 2026 — Luxor
- **Hotel:** Sonesta St. George Hotel - Luxor
- **Places:** Karnak Temple (08:00-11:00, 300 EGP), Ferry Tour (15:00-17:00, ~100 EGP)

### Day 4 — March 15, 2026 — Luxor
- **Hotel:** Sonesta St. George Hotel - Luxor
- **Places:** Hot Air Balloon (05:00-07:00, ~$80-150 USD), Luxor Temple (10:00-12:00, 260 EGP), Avenue of Sphinxes (12:00-13:00, Free)

### Day 5 — March 16, 2026 — Luxor
- **Hotel:** Sonesta St. George Hotel - Luxor
- **Places:** Valley of the Kings (07:00-10:00, 600 EGP/3 tombs), Mortuary Temple of Hatshepsut (10:30-12:00, 240 EGP), Colossi of Memnon (12:30-13:00, Free)

### Day 6 — March 17, 2026 — Luxor → Marsa Alam
- **Transport:** Drive, Luxor → Marsa Alam
- **Hotel:** JAZ Elite Maraya, Marsa Alam (Check-in)

### Day 7-9 — March 18-20, 2026 — Marsa Alam
- **Hotel:** JAZ Elite Maraya
- **Activities:** Resort & Beach (relax, snorkel, dive)

### Day 10 — March 21, 2026 — Marsa Alam → Cairo
- **Transport:** Flight, Marsa Alam → Cairo, 18:10 → 19:10
- **Hotel:** Novotel Cairo Airport Hotel (Check-in)

### Day 11 — March 22, 2026 — Cairo → Chengdu
- **Transport:** Flight 3U3864, Cairo CAI T2 → Chengdu TFU T1, 14:30 → 05:45+1

### Essential Info Items:
1. **Visa on Arrival** — USD $25, single entry, payable at airport counter before immigration. Bring passport photo.
2. **SIM Card** — Buy Vodafone or Orange SIM at Cairo Airport arrivals hall. ~200 EGP for 10GB/15 days.
3. **Currency Exchange** — Egyptian Pound (EGP). ~1 USD ≈ 50 EGP. Carry small bills for tips.
4. **Emergency Contacts** — Police: 122 | Ambulance: 123 | Chinese Embassy: +20-2-27361219
5. **Travel Insurance** — Keep policy number and emergency hotline screenshot offline.

---

## UI Details & Interactions

### Overview Tab
- Each day is a card showing: Day number badge (D1, D2...), date, city, summary text, and small pills for transport type / check-in / number of places
- Tap card → navigate to Day Detail

### Transport Tab
- Only shows days that have transport
- Each card shows: date, transport type pill, departure time + origin on left, arrival time + destination on right, connected by a line with transport icon, flight number below

### Hotels Tab
- Group consecutive nights at same hotel into one card
- Show: hotel name, address, date range, night count pill
- Two action buttons: "Copy Address" (copies to clipboard), "Open Maps" (opens Apple Maps with address)

### Places Tab
- Grouped by day with section headers "Day 1 · Mon, Mar 12"
- Each card: name with type icon (🏛️ attraction, 🎪 activity), address, time range, ticket price pill, notes in italic

### Info Tab
- Checklist style: each item has a checkbox, title, and expandable details
- Checked items become semi-transparent with strikethrough

### Day Detail
- Horizontal paging scroll (full-width cards, scroll snap)
- Each card: time pill (top-left), checkbox (top-right), large title, notes below, card counter at bottom
- Done cards: reduced opacity, strikethrough title
- Decorative circle shapes in bottom-right corner of each card (subtle, using theme color at very low opacity)

---

## Notes for Implementation

1. **Tab bar behavior:** When entering a trip, the bottom tab bar should smoothly transition from 3 app tabs to 5 trip tabs. The back button at top returns to app-level navigation.
2. **Seed data:** Check if Trip count is 0 on first launch, then insert the Egypt trip. Don't re-insert on subsequent launches.
3. **Offline-first:** No network calls. Everything works without internet.
4. **Language:** All UI text in English. Trip content can be in any language (Chinese characters should render correctly).
5. **Copy to clipboard:** Use `UIPasteboard.general.string` for the copy address feature.
6. **Open Maps:** Use `MKMapItem` with address string to open Apple Maps.