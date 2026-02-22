import SwiftUI
import UIKit

struct AccommodationTab: View {
    let trip: Trip

    /// Group consecutive nights at same hotel into one stay
    private var stays: [HotelStay] {
        var result: [HotelStay] = []
        var current: HotelStay? = nil

        for day in trip.sortedDays {
            guard let acc = day.accommodation else {
                current = nil
                continue
            }
            if let c = current, c.name == acc.name {
                current = HotelStay(name: c.name, address: c.address,
                                    startDate: c.startDate, endDate: day.date,
                                    nights: c.nights + 1)
                result[result.count - 1] = current!
            } else {
                let stay = HotelStay(name: acc.name, address: acc.address,
                                     startDate: day.date, endDate: day.date, nights: 1)
                current = stay
                result.append(stay)
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
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

                ForEach(stays) { stay in
                    HotelCard(stay: stay)
                }

                Spacer(minLength: 20)
            }
        }
    }
}

// MARK: - Data

struct HotelStay: Identifiable {
    let id = UUID()
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
                                .foregroundColor(Theme.primary)
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
                        bg: Theme.primaryFaint,
                        fg: Theme.primary
                    )
                }

                // Action buttons
                HStack(spacing: 8) {
                    Button {
                        UIPasteboard.general.string = stay.address
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        Label(copied ? "Copied!" : "Copy Address",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(copied ? Theme.primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button {
                        openInMaps(stay.address)
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
            }
        }
    }

    private func openInMaps(_ address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?address=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}
