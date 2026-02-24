import SwiftUI
import SwiftData

struct DestinationsTab: View {
    let trip: Trip

    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    @State private var selectedDest: Destination? = nil
    @State private var selectedEdit: Destination? = nil

    private var totalDestinations: Int {
        trip.days.reduce(0) { $0 + $1.destinations.count }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            List {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Places to Visit")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(totalDestinations) destination\(totalDestinations == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Theme.bg)
                .listRowSeparator(.hidden)

                let days = trip.sortedDays
                ForEach(Array(days.enumerated()), id: \.element.id) { i, day in
                    let dests = day.sortedDestinations
                    if !dests.isEmpty {
                        SectionHeader(title: "Day \(i + 1) · \(fmtDate(day.date))")
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Theme.bg)
                            .listRowSeparator(.hidden)

                        ForEach(dests) { dest in
                            DestinationCard(dest: dest, onTap: { selectedEdit = dest }) {
                                selectedDest = dest
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteDestination(dest, from: day)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Theme.bg)
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            AddButton { showAddSheet = true }
                .padding(.top, 14)
                .padding(.trailing, 20)
        }
        .sheet(isPresented: $showAddSheet) {
            AddPlaceSheet(trip: trip)
                .presentationDetents([.large])
        }
        .sheet(item: $selectedDest) { dest in
            PlaceDetailView(dest: dest, trip: trip)
        }
        .sheet(item: $selectedEdit) { dest in
            AddPlaceSheet(trip: trip, editing: dest)
                .presentationDetents([.large])
        }
    }

    private func deleteDestination(_ dest: Destination, from day: TripDay) {
        for d in trip.days {
            d.timelineItems.removeAll { $0.linkedId == dest.id }
        }
        if let idx = day.destinations.firstIndex(where: { $0.id == dest.id }) {
            day.destinations.remove(at: idx)
        }
        modelContext.delete(dest)
    }
}

private struct DestinationCard: View {
    let dest: Destination
    let onTap: () -> Void
    let onViewDetail: () -> Void

    var body: some View {
        CardView(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(dest.type.emoji) \(dest.name)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)

                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSec)
                            Text(dest.address)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSec)
                        }

                        if let t = dest.time {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSec)
                                Text(t)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSec)
                            }
                        }
                    }
                    Spacer()
                    if let price = dest.ticketPrice {
                        PillView(text: price,
                                 bg: Theme.attraction.opacity(0.15),
                                 fg: Theme.attraction)
                    }
                }

                if let notes = dest.notes, !notes.isEmpty {
                    Text("💡 \(notes)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTer)
                        .italic()
                }

                ViewDetailsButton(color: dest.type.color, action: onViewDetail)
            }
        }
    }
}

// MARK: - Add / Edit Place Sheet

private struct AddPlaceSheet: View {
    let trip: Trip
    private let editing: Destination?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedDayIndex = 0
    @State private var name: String
    @State private var type: DestinationType
    @State private var address: String
    @State private var time: String
    @State private var ticketPrice: String
    @State private var notes: String

    init(trip: Trip, editing: Destination? = nil) {
        self.trip = trip
        self.editing = editing
        _name        = State(initialValue: editing?.name ?? "")
        _type        = State(initialValue: editing?.type ?? .attraction)
        _address     = State(initialValue: editing?.address ?? "")
        _time        = State(initialValue: editing?.time ?? "")
        _ticketPrice = State(initialValue: editing?.ticketPrice ?? "")
        _notes       = State(initialValue: editing?.notes ?? "")
    }

    private var days: [TripDay] { trip.sortedDays }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if editing == nil {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Day")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textSec)
                                .textCase(.uppercase)
                                .kerning(0.8)
                            if !days.isEmpty {
                                Picker("Day", selection: $selectedDayIndex) {
                                    ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                                        Text("Day \(i + 1) · \(fmtDate(day.date))").tag(i)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .tint(Theme.primary)
                            }
                        }
                        .padding(.bottom, 4)
                    }

                    SheetField(label: "Name", text: $name, placeholder: "e.g. GIZA Pyramids")

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Type")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSec)
                            .textCase(.uppercase)
                            .kerning(0.8)
                        Picker("Type", selection: $type) {
                            ForEach(DestinationType.allCases, id: \.self) { t in
                                Text("\(t.emoji) \(t.rawValue.capitalized)").tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .tint(Theme.primary)
                    }
                    .padding(.bottom, 4)

                    SheetField(label: "Address", text: $address, placeholder: "Full address")
                    HStack(spacing: 10) {
                        SheetField(label: "Time", text: $time, placeholder: "08:00-12:00")
                        SheetField(label: "Ticket Price", text: $ticketPrice, placeholder: "540 EGP")
                    }
                    SheetField(label: "Notes", text: $notes, placeholder: "Tips...", multiline: true)

                    SheetSaveButton(label: "Save") {
                        guard !name.isEmpty else { return }
                        if let editing {
                            editing.name        = name
                            editing.type        = type
                            editing.address     = address
                            editing.time        = time.isEmpty ? nil : time
                            editing.ticketPrice = ticketPrice.isEmpty ? nil : ticketPrice
                            editing.notes       = notes.isEmpty ? nil : notes
                            for day in trip.days {
                                for item in day.timelineItems where item.linkedId == editing.id {
                                    item.title = "\(type.emoji) \(name)"
                                    item.time  = time.isEmpty ? "--:--" : time
                                }
                            }
                        } else {
                            guard !days.isEmpty else { return }
                            let dest = Destination(
                                name: name, type: type,
                                time: time.isEmpty ? nil : time,
                                address: address,
                                ticketPrice: ticketPrice.isEmpty ? nil : ticketPrice,
                                notes: notes.isEmpty ? nil : notes,
                                sortOrder: days[selectedDayIndex].destinations.count
                            )
                            modelContext.insert(dest)
                            days[selectedDayIndex].destinations.append(dest)

                            let tlItem = TimelineItem(
                                time: time.isEmpty ? "--:--" : time,
                                title: "\(type.emoji) \(name)",
                                type: type.timelineType,
                                linkedId: dest.id,
                                sortOrder: days[selectedDayIndex].timelineItems.count
                            )
                            modelContext.insert(tlItem)
                            days[selectedDayIndex].timelineItems.append(tlItem)
                        }
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle(editing != nil ? "Edit Place" : "Add Place")
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
