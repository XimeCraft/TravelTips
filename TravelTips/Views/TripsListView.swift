import SwiftUI
import SwiftData

struct TripsListView: View {
    let trips: [Trip]
    let onSelect: (Trip) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    @State private var tripToDelete: Trip? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            List {
                // Title header
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Trips")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("Plan it. Pack it. Go.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 6)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Theme.bg)
                .listRowSeparator(.hidden)

                SectionHeader(title: "Upcoming")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.bg)
                    .listRowSeparator(.hidden)

                if trips.isEmpty {
                    CardView {
                        VStack(spacing: 10) {
                            Text("🧳")
                                .font(.system(size: 40))
                            Text("No trips yet")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Create your first trip to start planning.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSec)
                                .multilineTextAlignment(.center)
                            Button {
                                showAddSheet = true
                            } label: {
                                Text("Create Trip")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(Theme.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.bg)
                    .listRowSeparator(.hidden)
                }

                ForEach(trips) { trip in
                    TripCard(trip: trip, onTap: { onSelect(trip) })
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                tripToDelete = trip
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Theme.bg)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            AddButton { showAddSheet = true }
                .padding(.top, 14)
                .padding(.trailing, 20)
        }
        .sheet(isPresented: $showAddSheet) {
            TripFormSheet()
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Delete this trip?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible,
            presenting: tripToDelete
        ) { trip in
            Button("Delete \"\(trip.name)\"", role: .destructive) {
                AttachmentStore.deleteAll(linkedTo: AttachmentStore.ownerIds(in: trip), context: modelContext)
                modelContext.delete(trip)
                tripToDelete = nil
            }
            Button("Cancel", role: .cancel) { tripToDelete = nil }
        } message: { trip in
            Text("All days, transport, hotels, places and info for \"\(trip.name)\" will be removed. This cannot be undone.")
        }
    }
}

// MARK: - Trip Card

private struct TripCard: View {
    let trip: Trip
    let onTap: () -> Void

    var body: some View {
        CardView(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [trip.color, trip.color.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(trip.emoji)
                        .font(.system(size: 28))
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(fmtDate(trip.startDate)) – \(fmtDate(trip.endDate))")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                    Text("\(trip.totalDays) days")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                let toStart = trip.daysLeft               // days until start day
                let toEnd = daysUntil(trip.endDate)       // negative once the end day has passed
                VStack(spacing: 0) {
                    if toStart > 0 {
                        // Upcoming
                        Text("\(toStart)")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Theme.primary)
                        Text("days left")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textTer)
                    } else if toEnd >= 0 {
                        // In progress
                        Text("Now")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Theme.primary)
                    } else {
                        // Ended — show days since the end day, e.g. "-25"
                        Text("\(toEnd)")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Theme.textTer)
                        Text("days ago")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textTer)
                    }
                }
            }
        }
    }
}
