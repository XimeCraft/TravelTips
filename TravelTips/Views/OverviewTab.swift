import SwiftUI

struct OverviewTab: View {
    let trip: Trip
    let onDay: (Int) -> Void

    @State private var showEdit = false

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(trip.emoji) \(trip.name)")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        ShareLink(item: TripShareText.make(trip),
                                  subject: Text("\(trip.emoji) \(trip.name)")) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(trip.tint)
                        }
                        .accessibilityLabel(Text("Share itinerary"))
                        Button { showEdit = true } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(trip.tint)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit trip")
                    }
                    HStack(spacing: 6) {
                        Text("\(fmtDate(trip.startDate)) – \(fmtDate(trip.endDate))")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSec)
                        Text("\(trip.totalDays) days")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(trip.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(trip.color.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)

                SectionHeader(title: "Daily Overview")

                let days = trip.sortedDays
                let todayIndex = trip.todayIndex()
                ForEach(Array(days.enumerated()), id: \.element.id) { i, day in
                    DayCard(day: day, dayNumber: i + 1, isToday: i == todayIndex,
                            accent: trip.color, accentText: trip.tint, onAccent: trip.onColor,
                            onTap: { onDay(i) })
                        .id(day.id)
                }

                Spacer(minLength: 20)
            }
        }
        .task(id: trip.id) {
            // Trip in progress: open on today's card. LazyVStack needs a layout
            // pass before the target row exists, hence the short wait.
            guard let i = trip.todayIndex(), i > 0 else { return }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(trip.sortedDays[i].id, anchor: .top)
            }
        }
        }
        .sheet(isPresented: $showEdit) {
            TripFormSheet(editing: trip)
                .presentationDetents([.medium, .large])
        }
    }
}

private struct DayCard: View {
    let day: TripDay
    let dayNumber: Int
    var isToday: Bool = false
    var accent: Color = Theme.primary
    var accentText: Color = Theme.primary
    var onAccent: Color = .white
    let onTap: () -> Void

    var body: some View {
        CardView(action: onTap, highlight: isToday ? accent : nil) {
            HStack(alignment: .top, spacing: 12) {
                // Day badge
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isToday ? accent : accent.opacity(0.19))
                    Text("D\(dayNumber)")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(isToday ? onAccent : accentText)
                }
                .frame(width: 44, height: 44)
                .flexibleFrame(maxWidth: 44)

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(fmtDate(day.date))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.textSec)
                        if isToday {
                            Text("TODAY")
                                .font(.system(size: 10, weight: .heavy))
                                .kerning(0.6)
                                .foregroundColor(onAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accent)
                                .cornerRadius(6)
                        }
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
                                text: "🏨 " + String(localized: "Check-in"),
                                bg: Theme.hotel.opacity(0.13),
                                fg: Theme.hotel
                            )
                        }
                        let destCount = day.destinations.count
                        if destCount > 0 {
                            PillView(
                                text: "📍 " + String(localized: "\(destCount) places"),
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

// MARK: - Today

extension Trip {
    /// Index into `sortedDays` of the day that is today, or nil if the trip
    /// isn't in progress (or today's day is missing).
    func todayIndex(now: Date = .now, calendar: Calendar = .current) -> Int? {
        sortedDays.firstIndex { calendar.isDate($0.date, inSameDayAs: now) }
    }
}
