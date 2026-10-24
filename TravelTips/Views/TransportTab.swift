import SwiftUI
import SwiftData

struct TransportTab: View {
    let trip: Trip

    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    @State private var selectedDetail: TransportDetailItem? = nil
    @State private var selectedEdit: TransportDetailItem? = nil

    private var transportDays: [(Int, TripDay, TransportInfo)] {
        var result: [(Int, TripDay, TransportInfo)] = []
        let days = trip.sortedDays
        for (i, day) in days.enumerated() {
            for transport in day.transports {
                result.append((i + 1, day, transport))
            }
        }
        return result
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            List {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transport")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("All flights & transfers")
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

                ForEach(transportDays, id: \.2.id) { dayNum, day, transport in
                    TransportCard(day: day, transport: transport, dayNumber: dayNum,
                                  onTap: { selectedEdit = TransportDetailItem(transport: transport, day: day) }) {
                        selectedDetail = TransportDetailItem(transport: transport, day: day)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteTransport(transport, from: day)
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
            AddTransportSheet(trip: trip)
                .presentationDetents([.medium])
        }
        .sheet(item: $selectedDetail) { item in
            TransportDetailView(transport: item.transport, day: item.day)
        }
        .sheet(item: $selectedEdit) { item in
            AddTransportSheet(trip: trip, editing: item.transport)
        }
    }

    private func deleteTransport(_ transport: TransportInfo, from day: TripDay) {
        AttachmentStore.deleteAll(linkedTo: [transport.id], context: modelContext)
        for d in trip.days {
            d.timelineItems.removeAll { $0.linkedId == transport.id }
        }
        if let idx = day.transports.firstIndex(where: { $0.id == transport.id }) {
            day.transports.remove(at: idx)
        }
        modelContext.delete(transport)
    }
}

// MARK: - Transport Detail Item (Identifiable wrapper)

struct TransportDetailItem: Identifiable {
    var id: UUID { transport.id }
    let transport: TransportInfo
    let day: TripDay
}

// MARK: - Transport Card

private struct TransportCard: View {
    let day: TripDay
    let transport: TransportInfo
    let dayNumber: Int
    let onTap: () -> Void
    let onViewDetail: () -> Void

    var body: some View {
        CardView(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    Text("Day \(dayNumber) · \(fmtDate(day.date))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSec)
                    Spacer()
                    PillView(
                        text: "\(transport.type.emoji) \(transport.type.displayName.uppercased())",
                        bg: Theme.transport.opacity(0.15),
                        fg: Theme.transport
                    )
                }

                HStack(spacing: 8) {
                    VStack(spacing: 3) {
                        Text(transport.departureTime.isEmpty ? "—" : transport.departureTime)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                        Text(transport.from)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSec)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 6) {
                        ZStack {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.transport.opacity(0.25), Theme.transport],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            Text(transport.type.emoji)
                                .font(.system(size: 16))
                                .background(Theme.card)
                                .padding(.horizontal, 4)
                        }
                        if !transport.detail.isEmpty {
                            Text(transport.detail)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.textTer)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 3) {
                        Text(transport.arrivalTime.isEmpty ? "—" : transport.arrivalTime)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                        Text(transport.to)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSec)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }

                ViewDetailsButton(color: Theme.transport, action: onViewDetail)
            }
        }
    }
}

// MARK: - Add / Edit Transport Sheet

private struct AddTransportSheet: View {
    let trip: Trip
    private let editing: TransportInfo?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedDayIndex = 0
    @State private var type: TransportType
    @State private var from: String
    @State private var to: String
    @State private var depTime: String
    @State private var arrTime: String
    @State private var detail: String

    init(trip: Trip, editing: TransportInfo? = nil) {
        self.trip = trip
        self.editing = editing
        _type    = State(initialValue: editing?.type ?? .flight)
        _from    = State(initialValue: editing?.from ?? "")
        _to      = State(initialValue: editing?.to ?? "")
        _depTime = State(initialValue: editing?.departureTime ?? "")
        _arrTime = State(initialValue: editing?.arrivalTime ?? "")
        _detail  = State(initialValue: editing?.detail ?? "")

        let initialDay = editing.flatMap { e in
            trip.sortedDays.firstIndex { $0.transports.contains(where: { $0.id == e.id }) }
        } ?? 0
        _selectedDayIndex = State(initialValue: initialDay)
    }

    private var days: [TripDay] { trip.sortedDays }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Day")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textSec)
                                .textCase(.uppercase)
                                .kerning(0.8)
                            if !days.isEmpty {
                                Picker("Day", selection: $selectedDayIndex) {
                                    ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                                        Text("Day \(i + 1), \(fmtDateShort(day.date))").tag(i)
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
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Type")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textSec)
                                .textCase(.uppercase)
                                .kerning(0.8)
                            Picker("Type", selection: $type) {
                                ForEach([TransportType.flight, .drive, .train, .bus, .ferry], id: \.self) { t in
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 4)

                    HStack(spacing: 10) {
                        SheetField(label: "From", text: $from, placeholder: "Departure")
                        SheetField(label: "To", text: $to, placeholder: "Arrival")
                    }
                    HStack(spacing: 10) {
                        SheetField(label: "Dep. Time", text: $depTime, placeholder: "08:00")
                        SheetField(label: "Arr. Time", text: $arrTime, placeholder: "10:30")
                    }
                    SheetField(label: "Detail", text: $detail, placeholder: "Flight number, etc.")

                    SheetSaveButton(label: "Save") {
                        if let editing {
                            editing.type = type
                            editing.from = from
                            editing.to   = to
                            editing.departureTime = depTime
                            editing.arrivalTime   = arrTime
                            editing.detail        = detail

                            // Move to the selected day if it changed.
                            guard !days.isEmpty else { dismiss(); return }
                            let targetDay = days[selectedDayIndex]
                            let currentDay = trip.days.first { $0.transports.contains(where: { $0.id == editing.id }) }
                            if let currentDay, currentDay.id != targetDay.id {
                                currentDay.transports.removeAll { $0.id == editing.id }
                                targetDay.transports.append(editing)
                                // Move its linked timeline items to the new day too.
                                for day in trip.days where day.id != targetDay.id {
                                    let moving = day.timelineItems.filter { $0.linkedId == editing.id }
                                    day.timelineItems.removeAll { $0.linkedId == editing.id }
                                    targetDay.timelineItems.append(contentsOf: moving)
                                }
                            }

                            for day in trip.days {
                                for item in day.timelineItems where item.linkedId == editing.id {
                                    item.title = "\(from) → \(to)"
                                    item.time  = depTime.isEmpty ? "--:--" : depTime
                                }
                            }
                        } else {
                            guard !from.isEmpty, !to.isEmpty, !days.isEmpty else { return }
                            let transport = TransportInfo(
                                type: type, detail: detail, from: from, to: to,
                                departureTime: depTime, arrivalTime: arrTime
                            )
                            modelContext.insert(transport)
                            days[selectedDayIndex].transports.append(transport)

                            let tlItem = TimelineItem(
                                time: depTime.isEmpty ? "--:--" : depTime,
                                title: "\(from) → \(to)",
                                type: type.timelineType,
                                linkedId: transport.id,
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
            .navigationTitle(editing != nil ? "Edit Transport" : "Add Transport")
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
