import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate) private var trips: [Trip]

    // Navigation state
    @State private var mainTab: MainTab = .trips
    @State private var selectedTrip: Trip? = nil
    @State private var tripTab: TripTab = .overview
    @State private var selectedDayIndex: Int? = nil

    private var inTrip: Bool { selectedTrip != nil }

    var body: some View {
        VStack(spacing: 0) {
            // ── Main content ────────────────────────────────────────────────
            ZStack {
                Theme.bg.ignoresSafeArea()

                if let trip = selectedTrip {
                    if let dayIdx = selectedDayIndex {
                        // Day detail — full screen, back returns to overview
                        DayDetailView(
                            trip: trip,
                            dayIndex: dayIdx,
                            onBack: { selectedDayIndex = nil }
                        )
                        .transition(.move(edge: .trailing))
                    } else {
                        // Trip with 5-tab content
                        VStack(spacing: 0) {
                            BackButton(label: "My Trips") {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedTrip = nil
                                    selectedDayIndex = nil
                                }
                            }

                            TripContentView(
                                trip: trip,
                                tab: tripTab,
                                onSelectDay: { idx in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        selectedDayIndex = idx
                                    }
                                }
                            )
                        }
                        .transition(.move(edge: .trailing))
                    }
                } else {
                    // Home: 3 main tabs
                    Group {
                        switch mainTab {
                        case .trips:
                            TripsListView(trips: trips) { trip in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedTrip = trip
                                    tripTab = .overview
                                    selectedDayIndex = nil
                                }
                            }
                        case .reminders:
                            RemindersView(trips: trips)
                        case .settings:
                            SettingsView()
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: selectedTrip?.id)
            .animation(.easeInOut(duration: 0.2), value: selectedDayIndex)

            // ── Tab bar ─────────────────────────────────────────────────────
            AppTabBar(
                inTrip: inTrip,
                mainTab: $mainTab,
                tripTab: $tripTab,
                onTripTabChange: { selectedDayIndex = nil }
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            seedIfNeeded(context: modelContext)
        }
    }
}

// MARK: - Trip content switcher

private struct TripContentView: View {
    let trip: Trip
    let tab: TripTab
    let onSelectDay: (Int) -> Void

    var body: some View {
        switch tab {
        case .overview:
            OverviewTab(trip: trip, onDay: onSelectDay)
        case .transport:
            TransportTab(trip: trip)
        case .accommodation:
            AccommodationTab(trip: trip)
        case .destinations:
            DestinationsTab(trip: trip)
        case .info:
            InfoTab(trip: trip)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trip.self, TripDay.self, TransportInfo.self,
                               Accommodation.self, Destination.self,
                               TimelineItem.self, InfoItem.self],
                        inMemory: true)
}
