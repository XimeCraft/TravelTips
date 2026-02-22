import SwiftUI

struct TripsListView: View {
    let trips: [Trip]
    let onSelect: (Trip) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
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

                SectionHeader(title: "Upcoming")

                ForEach(trips) { trip in
                    TripCard(trip: trip, onTap: { onSelect(trip) })
                }

                // Add new trip placeholder
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add New Trip")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.primary.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.primary.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 6)

                Spacer(minLength: 20)
            }
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
                // Emoji badge
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

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(fmtDate(trip.startDate)) – \(fmtDate(trip.endDate)) · \(trip.totalDays) days")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Countdown
                let d = trip.daysLeft
                VStack(spacing: 0) {
                    Text(d > 0 ? "\(d)" : "Now")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.primary)
                    if d > 0 {
                        Text("days left")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textTer)
                    }
                }
            }
        }
    }
}
