import SwiftUI

struct OverviewTab: View {
    let trip: Trip
    let onDay: (Int) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(trip.emoji) \(trip.name)")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    HStack(spacing: 6) {
                        Text("\(fmtDate(trip.startDate)) – \(fmtDate(trip.endDate))")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSec)
                        Text("\(trip.totalDays) days")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.primary.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)

                SectionHeader(title: "Daily Overview")

                let days = trip.sortedDays
                ForEach(Array(days.enumerated()), id: \.element.id) { i, day in
                    DayCard(day: day, dayNumber: i + 1, onTap: { onDay(i) })
                }

                Spacer(minLength: 20)
            }
        }
    }
}

private struct DayCard: View {
    let day: TripDay
    let dayNumber: Int
    let onTap: () -> Void

    var body: some View {
        CardView(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Day badge
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.primaryMuted)
                    Text("D\(dayNumber)")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.primary)
                }
                .frame(width: 44, height: 44)
                .flexibleFrame(maxWidth: 44)

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(fmtDate(day.date))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.textSec)
                        Spacer()
                        Text(day.city)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                    }

                    Text(day.summary)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(2)
                        .padding(.top, 4)

                    // Pills — MVP2 colors and icons (FlowHStack wraps whole pill to next row)
                    FlowHStack(spacing: 5) {
                        if let t = day.firstTransport {
                            PillView(
                                text: "\(t.type.emoji) \(t.type.displayName)",
                                bg: Theme.transport.opacity(0.15),
                                fg: Theme.transport
                            )
                        }
                        if day.accommodation?.isCheckIn == true {
                            PillView(
                                text: "🏨 Check-in",
                                bg: Theme.hotel.opacity(0.13),
                                fg: Theme.hotel
                            )
                        }
                        let destCount = day.destinations.count
                        if destCount > 0 {
                            PillView(
                                text: "📍 \(destCount) place\(destCount > 1 ? "s" : "")",
                                bg: Theme.attraction.opacity(0.15),
                                fg: Theme.attraction
                            )
                        }
                    }
                    .padding(.top, 7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray4))
                    .padding(.top, 12)
            }
        }
    }
}

// MARK: - Helper

extension View {
    func flexibleFrame(maxWidth: CGFloat) -> some View {
        self.frame(minWidth: maxWidth, maxWidth: maxWidth)
    }
}
