import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Trip.startKey) private var trips: [Trip]   // "yyyy-MM-dd" sorts chronologically

    // Navigation state
    @State private var mainTab: MainTab = .trips
    @State private var selectedTrip: Trip? = nil
    @State private var tripTab: TripTab = .overview
    @State private var selectedDayIndex: Int? = nil
    @AppStorage(StoreSetup.recoveryNoticeKey) private var recoveryNotice: String = ""

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
                            BackButton(label: "My Trips", color: trip.color) {
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
                tripAccent: selectedTrip?.color ?? Theme.primary,
                mainTab: $mainTab,
                tripTab: $tripTab,
                onTripTabChange: { selectedDayIndex = nil }
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.light)   // app is designed light-only; lock it to avoid dark-on-dark
        .alert("Data Recovery", isPresented: Binding(
            get: { !recoveryNotice.isEmpty },
            set: { if !$0 { recoveryNotice = "" } }
        )) {
            Button("OK", role: .cancel) { recoveryNotice = "" }
        } message: {
            Text(recoveryNotice)
        }
        .onChange(of: scenePhase) { _, phase in
            // Rebuild trip reminders when the app opens and when it is left, so
            // edits made in between are reflected.
            if phase == .active || phase == .background {
                Task { await NotificationScheduler.reschedule(context: modelContext) }
            }
        }
        .onAppear {
            // Sample data is for development only; Release starts empty (see A6).
            #if DEBUG
            seedIfNeeded(context: modelContext)
            seedPackingIfNeeded(context: modelContext)
            #endif
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
        case .packing:
            PackingTab()
        case .info:
            InfoTab(trip: trip)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trip.self, TripDay.self, TransportInfo.self,
                               Accommodation.self, Destination.self,
                               TimelineItem.self, InfoItem.self, TaskItem.self,
                               Attachment.self, PackingItem.self, PackingTag.self],
                        inMemory: true)
}
