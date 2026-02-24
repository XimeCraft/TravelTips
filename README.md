# TravelTips

A clean, offline-first iOS travel planner built with SwiftUI and SwiftData. Plan itineraries, track transport, manage accommodation, log destinations, and stay organised — all from one app.

## Screenshots

> Coming soon — run on simulator to see the app in action.

## Features

### My Trips
- Create and manage multiple trips with name, emoji, start/end dates
- Countdown "days left" badge on each trip card
- Swipe to delete a trip (cascade-deletes all data)
- Tap card to open the full trip planner

### Overview Tab
- Per-day summary cards with city, date, and a short description
- Colour-coded pills for transport, check-in, and places count
- FlowHStack pill layout wraps cleanly to the next row

### Daily Timeline (Day Detail)
- Chronological timeline of every event for a day
- Colour-coded by type: flight, drive, train, bus, ferry, hotel, attraction, restaurant, activity
- Add manual timeline entries with time, title, note, and type
- Check off items as done (strikethrough + fade)
- Swipe to delete manual entries; linked entries (synced from other tabs) are protected
- Edit day metadata: city name and day summary

### Transport Tab
- All flights, drives, trains, buses, and ferries across the trip
- Visual departure → arrival card with times and route line
- Add/edit: day picker, type picker, from/to, departure/arrival times, detail (flight number, etc.)
- Adding a transport auto-creates a matching Daily timeline entry
- Editing syncs the title and time in Daily
- Swipe to delete (cascade-removes the linked Daily entry)

### Accommodation Tab
- Aggregated hotel stay cards showing check-in, check-out, and total nights
- Copy address to clipboard or open in Apple Maps
- Add hotel: check-in date + check-out date pickers; creates one `Accommodation` record per night
- Check-in and check-out timeline entries auto-created in Daily on save
- Edit hotel: update name and address across all nights; syncs timeline item titles
- Swipe to delete a stay (removes all nights and linked timeline entries)

### Destinations Tab
- Places grouped by day with type (attraction, activity, restaurant, shopping)
- Address, visit time, ticket price, and notes per place
- Adding a place auto-creates a timeline entry in Daily
- Editing syncs the Daily entry title/time
- Swipe to delete (cascade-removes the linked Daily entry)
- Open Maps button on each card

### Info Tab
- Trip-wide reference cards: visa info, SIM cards, emergency contacts, etc.
- Add/edit title and multi-line details
- Swipe to delete

### Detail Views (MVP3)
- **Transport Detail** — full breakdown of a single leg: type, route, times, flight number, attachments
- **Hotel Detail** — stay overview with all nights, address, check-in/out times, attachments
- **Place Detail** — full place card with map link, ticket price, notes, attachments
- **Info Detail** — expanded notes view with attachment support
- **Attachments** — attach PDFs or photos to any item via Files picker or Camera; preview PDFs in-app via QuickLook; view photos full-screen

### Todo Tab
- **Trip Reminders** (auto) — computed reminders from existing trips (days away, transport count, hotel nights)
- **My Tasks** (manual) — personal checklist; add inline, check off, swipe to delete

### Settings
- Language preference (stored in UserDefaults)
- Notification toggle with system permission request
- App version display

## Architecture

```
TravelTips/
├── Models/
│   └── Models.swift          # All SwiftData models
├── Components/
│   └── SharedComponents.swift # CardView, PillView, FlowHStack, CheckboxView, AddButton, …
├── Views/
│   ├── TripsListView.swift    # Home screen — trip list + new trip sheet
│   ├── OverviewTab.swift      # Day-by-day overview
│   ├── DayDetailView.swift    # Daily timeline editor
│   ├── TransportTab.swift     # Transport list + add/edit sheet
│   ├── AccommodationTab.swift # Hotel list + add/edit sheet
│   ├── DestinationsTab.swift  # Places list + add/edit sheet
│   ├── InfoTab.swift          # Reference info list + add/edit sheet
│   ├── DetailViews.swift      # Full detail + attachment views (MVP3)
│   ├── RemindersView.swift    # Todo tab
│   └── SettingsView.swift     # App settings
├── Data/
│   └── SeedData.swift         # Egypt trip seed (first-launch only)
├── Theme.swift                # Colors, typography, date helpers
├── ContentView.swift          # Root tab + trip navigation
└── TravelTipsApp.swift        # App entry, ModelContainer init
```

### Data Model

```
Trip
 ├── [TripDay]
 │    ├── [TransportInfo]
 │    ├── Accommodation?
 │    ├── [Destination]
 │    └── [TimelineItem]  ← linkedId → source Transport/Hotel/Destination
 └── [InfoItem]

TaskItem  (standalone, Todo tab)
Attachment (linked to any item by UUID)
```

**Key invariant:** every TransportInfo, Accommodation, and Destination that is added automatically produces a `TimelineItem` with `linkedId` set. Deleting the source cascades to remove the linked item. Manual timeline entries have `linkedId == nil` and can be freely deleted.

## Tech Stack

| | |
|---|---|
| Platform | iOS 17+ |
| Language | Swift 5.9 |
| UI | SwiftUI |
| Persistence | SwiftData |
| File handling | UIDocumentPickerViewController, AVFoundation, QuickLook |
| Architecture | Single-store SwiftData, MVVM-lite (computed properties on models) |

## Getting Started

1. Clone the repo
2. Open `TravelTips.xcodeproj` in Xcode 15+
3. Select any iOS 17 simulator or device
4. Build & run — an Egypt trip is seeded automatically on first launch

## License

MIT
