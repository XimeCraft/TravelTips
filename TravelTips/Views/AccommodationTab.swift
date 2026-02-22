import SwiftUI
import UIKit
import SwiftData

struct AccommodationTab: View {
    let trip: Trip

    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false

    private var stays: [HotelStay] {
        var result: [HotelStay] = []
        var current: HotelStay? = nil
        var currentLinkedId: UUID? = nil
        for day in trip.sortedDays {
            guard let acc = day.accommodation else { current = nil; currentLinkedId = nil; continue }
            if let c = current, c.name == acc.name {
                current = HotelStay(linkedId: currentLinkedId, name: c.name, address: c.address,
                                    startDate: c.startDate, endDate: day.date,
                                    nights: c.nights + 1)
                result[result.count - 1] = current!
            } else {
                currentLinkedId = acc.id
                let stay = HotelStay(linkedId: acc.id, name: acc.name, address: acc.address,
                                     startDate: day.date, endDate: day.date, nights: 1)
                current = stay
                result.append(stay)
            }
        }
        return result
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            List {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accommodation")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(stays.count) hotel\(stays.count == 1 ? "" : "s")")
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

                ForEach(stays) { stay in
                    HotelCard(stay: stay)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteStay(stay)
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
            AddHotelSheet(trip: trip)
                .presentationDetents([.medium])
        }
    }

    private func deleteStay(_ stay: HotelStay) {
        for day in trip.days {
            if day.accommodation?.name == stay.name {
                if let acc = day.accommodation { modelContext.delete(acc) }
                day.accommodation = nil
            }
        }
        if let lid = stay.linkedId {
            for day in trip.days {
                day.timelineItems.removeAll { $0.linkedId == lid }
            }
        }
    }
}

// MARK: - Data

struct HotelStay: Identifiable {
    let id = UUID()
    let linkedId: UUID?
    let name: String
    let address: String
    let startDate: Date
    let endDate: Date
    let nights: Int
}

// MARK: - Hotel Card

private struct HotelCard: View {
    let stay: HotelStay
    @State private var copied = false

    var body: some View {
        CardView {
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "bed.double.fill")
                                .foregroundColor(Theme.hotel)
                            Text(stay.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSec)
                            Text(stay.address)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSec)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSec)
                            Text("\(fmtDate(stay.startDate)) – \(fmtDate(stay.endDate))")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSec)
                        }
                    }
                    Spacer()
                    PillView(
                        text: "\(stay.nights) night\(stay.nights == 1 ? "" : "s")",
                        bg: Theme.hotel.opacity(0.13),
                        fg: Theme.hotel
                    )
                }

                HStack(spacing: 8) {
                    Button {
                        UIPasteboard.general.string = stay.address
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        Label(copied ? "Copied!" : "Copy Address",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(copied ? Theme.hotel : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button {
                        let encoded = stay.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "maps://?address=\(encoded)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Maps", systemImage: "map")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }

                ViewDetailsButton(color: Theme.hotel)
            }
        }
    }
}

// MARK: - Add Hotel Sheet

private struct AddHotelSheet: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var hotelName = ""
    @State private var address = ""
    @State private var checkInDate: Date
    @State private var checkOutDate: Date

    init(trip: Trip) {
        self.trip = trip
        _checkInDate = State(initialValue: trip.startDate)
        _checkOutDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 2, to: trip.startDate) ?? trip.startDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    SheetField(label: "Hotel Name", text: $hotelName, placeholder: "e.g. Ramses Hilton")
                    SheetField(label: "Address", text: $address, placeholder: "Full address")

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Check-in")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textSec)
                                .textCase(.uppercase)
                                .kerning(0.8)
                            DatePicker("", selection: $checkInDate,
                                       in: trip.startDate...trip.endDate,
                                       displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(Theme.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Check-out")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textSec)
                                .textCase(.uppercase)
                                .kerning(0.8)
                            DatePicker("", selection: $checkOutDate,
                                       in: checkInDate...trip.endDate,
                                       displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(Theme.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 4)

                    SheetSaveButton(label: "Save") {
                        guard !hotelName.isEmpty else { return }
                        let cal = Calendar.current
                        let days = trip.sortedDays
                        var firstAccId: UUID? = nil
                        var current = cal.startOfDay(for: checkInDate)
                        let checkOut = cal.startOfDay(for: checkOutDate)

                        while current < checkOut {
                            if let matchDay = days.first(where: { cal.isDate($0.date, inSameDayAs: current) }) {
                                let acc = Accommodation(name: hotelName, address: address,
                                                        isCheckIn: current == cal.startOfDay(for: checkInDate))
                                modelContext.insert(acc)
                                matchDay.accommodation = acc
                                if firstAccId == nil { firstAccId = acc.id }
                            }
                            current = cal.date(byAdding: .day, value: 1, to: current) ?? checkOut
                        }

                        if let lid = firstAccId,
                           let inDay = days.first(where: { cal.isDate($0.date, inSameDayAs: checkInDate) }) {
                            let tlIn = TimelineItem(time: "--:--", title: "Check-in · \(hotelName)",
                                                    type: .hotel, linkedId: lid,
                                                    sortOrder: inDay.timelineItems.count)
                            modelContext.insert(tlIn)
                            inDay.timelineItems.append(tlIn)
                        }

                        if let lid = firstAccId,
                           let outDay = days.first(where: { cal.isDate($0.date, inSameDayAs: checkOutDate) }) {
                            let tlOut = TimelineItem(time: "--:--", title: "Check-out · \(hotelName)",
                                                     type: .hotel, linkedId: lid,
                                                     sortOrder: outDay.timelineItems.count)
                            modelContext.insert(tlOut)
                            outDay.timelineItems.append(tlOut)
                        }

                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Hotel")
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
