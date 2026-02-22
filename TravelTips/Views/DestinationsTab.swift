import SwiftUI

struct DestinationsTab: View {
    let trip: Trip

    private var totalDestinations: Int {
        trip.days.reduce(0) { $0 + $1.destinations.count }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
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

                let days = trip.sortedDays
                ForEach(Array(days.enumerated()), id: \.element.id) { i, day in
                    let dests = day.sortedDestinations
                    if !dests.isEmpty {
                        SectionHeader(title: "Day \(i + 1) · \(fmtDate(day.date))")

                        ForEach(dests) { dest in
                            DestinationCard(dest: dest)
                        }
                    }
                }

                Spacer(minLength: 20)
            }
        }
    }
}

private struct DestinationCard: View {
    let dest: Destination

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(dest.type.icon) \(dest.name)")
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
                        PillView(text: price, bg: Color(hex: "FFF8E1"), fg: Color(hex: "F9A825"))
                    }
                }

                if let notes = dest.notes, !notes.isEmpty {
                    Text("💡 \(notes)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTer)
                        .italic()
                }
            }
        }
    }
}
