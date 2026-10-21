import SwiftUI
import SwiftData

struct TripsListView: View {
    let trips: [Trip]
    let onSelect: (Trip) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false

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

                ForEach(trips) { trip in
                    TripCard(trip: trip, onTap: { onSelect(trip) })
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(trip)
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
            NewTripSheet()
                .presentationDetents([.medium])
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
                                colors: [Theme.primary, Theme.primaryLight],
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

// MARK: - New Trip Sheet

private struct NewTripSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var emoji = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7)

    private let quickEmojis = ["🇨🇳","🇳🇿","🇸🇬","🇯🇵","🇰🇷","🇺🇸","🇬🇧","🇫🇷","🇩🇪","🇮🇹",
                               "🇪🇸","🇹🇭","🇦🇪","🇪🇬","🇲🇦","🇹🇷","🇬🇷","🇵🇹","🇦🇺","✈️","🏖️","🏔️","🗺️","🧳"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    SheetField(label: "Trip Name", text: $name, placeholder: "e.g. Egypt")

                    // Emoji field with quick-select row
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Emoji")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSec)
                            .textCase(.uppercase)
                            .kerning(0.8)
                        TextField("🌍", text: $emoji)
                            .font(.system(size: 22))
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickEmojis, id: \.self) { flag in
                                    Button {
                                        emoji = flag
                                    } label: {
                                        Text(flag)
                                            .font(.system(size: 24))
                                            .padding(6)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 4)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Start Date")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSec)
                            .textCase(.uppercase)
                            .kerning(0.8)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(Theme.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("End Date")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSec)
                            .textCase(.uppercase)
                            .kerning(0.8)
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(Theme.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)

                    SheetSaveButton(label: "Create Trip") {
                        guard !name.isEmpty else { return }
                        let trip = Trip(
                            name: name,
                            emoji: emoji.isEmpty ? "✈️" : emoji,
                            startDate: startDate,
                            endDate: endDate
                        )
                        let calendar = Calendar.current
                        var current = startDate
                        var sortOrder = 0
                        while current <= endDate {
                            let day = TripDay(date: current, city: "", summary: "", sortOrder: sortOrder)
                            trip.days.append(day)
                            current = calendar.date(byAdding: .day, value: 1, to: current) ?? endDate.addingTimeInterval(86400)
                            sortOrder += 1
                        }
                        modelContext.insert(trip)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }
}
