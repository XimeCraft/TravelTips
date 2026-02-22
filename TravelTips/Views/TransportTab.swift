import SwiftUI

struct TransportTab: View {
    let trip: Trip

    private var transportDays: [(Int, TripDay)] {
        trip.sortedDays
            .enumerated()
            .filter { $0.element.transport != nil }
            .map { ($0.offset + 1, $0.element) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
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

                ForEach(transportDays, id: \.1.id) { dayNum, day in
                    if let t = day.transport {
                        TransportCard(day: day, transport: t, dayNumber: dayNum)
                    }
                }

                Spacer(minLength: 20)
            }
        }
    }
}

private struct TransportCard: View {
    let day: TripDay
    let transport: TransportInfo
    let dayNumber: Int

    private var isFlight: Bool { transport.type == .flight }

    var body: some View {
        CardView {
            VStack(spacing: 12) {
                // Date + Type pill
                HStack {
                    Text("Day \(dayNumber) · \(fmtDate(day.date))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSec)
                    Spacer()
                    PillView(
                        text: "\(transport.type.icon) \(transport.type.displayName.uppercased())",
                        bg: isFlight ? Color(hex: "E3F2ED") : Color(hex: "FFF8E1"),
                        fg: isFlight ? Theme.primary : Color(hex: "F9A825")
                    )
                }

                // From → To
                HStack(spacing: 8) {
                    // Departure
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

                    // Line + icon
                    VStack(spacing: 6) {
                        ZStack {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.primary.opacity(0.25), Theme.primary],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            Text(transport.type.icon)
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

                    // Arrival
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
            }
        }
    }
}
