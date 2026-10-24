import SwiftUI
import SwiftData

// MARK: - Main View

struct DayDetailView: View {
    let trip: Trip
    let dayIndex: Int
    let onBack: () -> Void

    @State private var currentDayIndex: Int
    @State private var showAddSheet = false

    init(trip: Trip, dayIndex: Int, onBack: @escaping () -> Void) {
        self.trip = trip
        self.dayIndex = dayIndex
        self.onBack = onBack
        _currentDayIndex = State(initialValue: dayIndex)
    }

    private var days: [TripDay] { trip.sortedDays }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ───────────────────────────────────────────────────────
            HStack(alignment: .top, spacing: 0) {
                BackButton(label: "Overview", action: onBack)
                Spacer()
                AddButton { showAddSheet = true }
                    .padding(.top, 18)
                    .padding(.trailing, 20)
            }

            if !days.isEmpty {
                let day = days[min(currentDayIndex, days.count - 1)]
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day \(currentDayIndex + 1)")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(fmtDate(day.date)) · \(day.city)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 2)
                .padding(.bottom, 10)
            }

            // ── Swipeable day cards ──────────────────────────────────────────
            TabView(selection: $currentDayIndex) {
                ForEach(Array(days.enumerated()), id: \.element.id) { idx, day in
                    DayCard(day: day, trip: trip)
                        .padding(.horizontal, 25)
                        .padding(.bottom, 4)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // ── Dot indicators ───────────────────────────────────────────────
            HStack(spacing: 5) {
                ForEach(0..<days.count, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.3)) { currentDayIndex = i }
                    } label: {
                        RoundedRectangle(cornerRadius: 3)
                            .frame(width: currentDayIndex == i ? 20 : 6, height: 6)
                            .foregroundColor(currentDayIndex == i ? Theme.primary : Color(.systemGray4))
                            .animation(.spring(response: 0.3), value: currentDayIndex)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 10)
        }
        .sheet(isPresented: $showAddSheet) {
            if !days.isEmpty {
                AddTimelineItemSheet(day: days[min(currentDayIndex, days.count - 1)])
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Day Card

private struct DayCard: View {
    let day: TripDay
    let trip: Trip

    @Environment(\.modelContext) private var modelContext

    private var items: [TimelineItem] { day.sortedTimelineItems }
    private var doneCount: Int { items.filter { $0.isDone }.count }

    var body: some View {
        VStack(spacing: 0) {
            // Day done header
            Button {
                let allDone = !day.dayDone
                day.dayDone = allDone
                for item in day.timelineItems { item.isDone = allDone }
            } label: {
                HStack(spacing: 10) {
                    CheckboxView(isChecked: day.dayDone, color: Theme.primary, size: 20) {
                        let allDone = !day.dayDone
                        day.dayDone = allDone
                        for item in day.timelineItems { item.isDone = allDone }
                    }
                    Text(day.dayDone ? "Day completed ✓" : "Mark day as done")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(day.dayDone ? Theme.primary : Theme.textSec)
                    Spacer()
                    Text("\(doneCount)/\(items.count)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTer)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(day.dayDone ? Theme.primary.opacity(0.08) : Color(.systemGray6))
            }
            .buttonStyle(.plain)

            Divider()

            // Timeline items — List enables swipeActions
            List {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                    TimelineItemRow(item: item, trip: trip, isLast: i == items.count - 1)
                        .swipeActions(edge: .trailing) {
                            // Only manual items (no linkedId) can be deleted here;
                            // linked items must be deleted from Transport/Hotels/Places tab
                            if item.linkedId == nil {
                                Button(role: .destructive) {
                                    delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .contextMenu {
                            // Reliable fallback: the day-paging TabView can intercept the
                            // horizontal swipe gesture, so offer delete via long-press too.
                            if item.linkedId == nil {
                                Button(role: .destructive) {
                                    delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Theme.card)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 2)
    }

    // Deferred to the next runloop tick to avoid mutating SwiftData during view render.
    private func delete(_ item: TimelineItem) {
        DispatchQueue.main.async {
            day.timelineItems.removeAll { $0.id == item.id }
            modelContext.delete(item)
        }
    }
}

// MARK: - Timeline Item Row

private struct TimelineItemRow: View {
    let item: TimelineItem
    let trip: Trip
    let isLast: Bool

    @State private var showDetail = false

    private var displayTime: String {
        if item.type == .flight, let linkedId = item.linkedId,
           let (transport, _) = trip.findTransport(linkedId: linkedId),
           !transport.departureTime.isEmpty, !transport.arrivalTime.isEmpty {
            return "\(transport.departureTime) - \(transport.arrivalTime)"
        }
        return item.time
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Color bar
            Rectangle()
                .fill(item.type.color)
                .frame(width: 4)

            HStack(alignment: .top, spacing: 8) {
                // Checkbox
                CheckboxView(isChecked: item.isDone, color: item.type.color, size: 18) {
                    item.isDone.toggle()
                }
                .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    // Time badge + emoji icon
                    HStack(spacing: 5) {
                        Text(displayTime)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(item.type.color)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(item.type.color.opacity(0.12))
                            .cornerRadius(5)
                        Text(item.type.emoji)
                            .font(.system(size: 12))
                    }

                    // Title
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .strikethrough(item.isDone)

                    // Note
                    if let note = item.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSec)
                            .lineSpacing(3)
                    }

                    // Address
                    if let address = item.address, !address.isEmpty {
                        Text("📍 \(address)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSec)
                    }

                    // Linked preview
                    if let linkedId = item.linkedId {
                        LinkedPreview(linkedId: linkedId, itemType: item.type, trip: trip)
                    }

                    // View details — only for linked items
                    if item.linkedId != nil {
                        Button {
                            showDetail = true
                        } label: {
                            Text("View details ›")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(item.type.color)
                                .padding(.top, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 12)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 11)
        }
        .opacity(item.isDone ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: item.isDone)
        .sheet(isPresented: $showDetail) {
            resolvedDetailView
        }

        if !isLast {
            Divider().padding(.leading, 4)
        }
    }

    @ViewBuilder
    private var resolvedDetailView: some View {
        if let linkedId = item.linkedId {
            if item.type.isTransport, let (transport, day) = trip.findTransport(linkedId: linkedId) {
                TransportDetailView(transport: transport, day: day)
            } else if item.type == .hotel {
                HotelDetailView(trip: trip, linkedId: linkedId)
            } else if let dest = trip.findDestination(linkedId: linkedId) {
                PlaceDetailView(dest: dest, trip: trip)
            } else {
                Text("Detail not available")
                    .foregroundColor(Theme.textSec)
                    .padding()
            }
        }
    }
}

// MARK: - Linked Preview Box

private struct LinkedPreview: View {
    let linkedId: UUID
    let itemType: TimelineType
    let trip: Trip

    var body: some View {
        Group {
            if itemType.isTransport, let (transport, day) = trip.findTransport(linkedId: linkedId) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(transport.from) → \(transport.to)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.transport)
                        Spacer()
                    }
                    HStack(spacing: 4) {
                        if !transport.departureTime.isEmpty || !transport.arrivalTime.isEmpty {
                            Text("\(transport.departureTime) → \(transport.arrivalTime)")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSec)
                        }
                        if !transport.detail.isEmpty {
                            Text("· \(transport.detail)")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSec)
                        }
                    }
                    Text("📅 \(fmtDate(day.date))")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTer)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Theme.transport.opacity(0.08))
                .cornerRadius(8)

            } else if itemType == .hotel, let acc = trip.findAccommodation(linkedId: linkedId) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(acc.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.hotel)
                    Text("📍 \(acc.address)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSec)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Theme.hotel.opacity(0.08))
                .cornerRadius(8)

            } else if let dest = trip.findDestination(linkedId: linkedId) {
                let c = dest.type.color
                VStack(alignment: .leading, spacing: 2) {
                    Text(dest.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(c)
                    HStack(spacing: 4) {
                        Text("📍 \(dest.address)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSec)
                        if let price = dest.ticketPrice {
                            Text("· \(price)")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSec)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(c.opacity(0.08))
                .cornerRadius(8)
            }
        }
        .padding(.top, 2)
    }
}

// MARK: - Add Timeline Item Sheet

private struct AddTimelineItemSheet: View {
    let day: TripDay

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var time = ""
    @State private var title = ""
    @State private var address = ""
    @State private var note = ""
    @State private var type: TimelineType = .other

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    TimeField(label: "Time", text: $time)
                    SheetField(label: "Title", text: $title, placeholder: "What to do")
                    SheetField(label: "Address", text: $address, placeholder: "Location address")

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Type")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSec)
                            .textCase(.uppercase)
                            .kerning(0.8)
                        Picker("Type", selection: $type) {
                            ForEach(TimelineType.allCases, id: \.self) { t in
                                Text("\(t.emoji) \(t.displayName)").tag(t)
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

                    SheetField(label: "Notes", text: $note, placeholder: "Additional details...", multiline: true)

                    SheetSaveButton(label: "Save") {
                        guard !title.isEmpty else { return }
                        let item = TimelineItem(
                            time: time.isEmpty ? "--:--" : time,
                            title: title,
                            note: note.isEmpty ? nil : note,
                            address: address.isEmpty ? nil : address,
                            type: type,
                            sortOrder: day.timelineItems.count
                        )
                        modelContext.insert(item)
                        day.timelineItems.append(item)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Timeline Item")
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
