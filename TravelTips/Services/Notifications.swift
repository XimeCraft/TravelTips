import Foundation
import SwiftData
import UserNotifications

// MARK: - Planning (pure, testable)

/// A notification we intend to deliver at a local wall-clock time.
struct PlannedNotification: Equatable {
    let id: String
    let fire: DateComponents      // year/month/day/hour/minute, no time zone → device's local time
    let title: String
    let body: String
}

enum NotificationPlanner {
    static let idPrefix = "trip-"
    /// iOS keeps at most 64 pending requests per app; leave headroom.
    static let maxPending = 60
    static let eveHour = 20
    static let morningHour = 8

    /// Notifications for every trip whose fire time is still in the future,
    /// nearest first, capped at `maxPending`.
    static func plan(for trips: [Trip], now: Date = .now, calendar: Calendar = .current) -> [PlannedNotification] {
        var result: [(Date, PlannedNotification)] = []

        for trip in trips {
            let days = trip.sortedDays
            guard let first = days.first else { continue }

            // Evening before the trip starts.
            if let eve = calendar.date(byAdding: .day, value: -1, to: first.date),
               let fire = at(eveHour, on: eve, calendar), fire > now {
                result.append((fire, PlannedNotification(
                    id: "\(idPrefix)\(trip.id)-eve",
                    fire: components(fire, calendar),
                    title: "\(trip.emoji) \(trip.name) starts tomorrow",
                    body: "Day 1 · " + summary(of: first)
                )))
            }

            // Every morning of the trip.
            for (i, day) in days.enumerated() {
                guard let fire = at(morningHour, on: day.date, calendar), fire > now else { continue }
                let place = day.city.trimmingCharacters(in: .whitespaces)
                result.append((fire, PlannedNotification(
                    id: "\(idPrefix)\(trip.id)-day\(i + 1)",
                    fire: components(fire, calendar),
                    title: "\(trip.emoji) Day \(i + 1)" + (place.isEmpty ? " of \(trip.name)" : " · \(place)"),
                    body: summary(of: day)
                )))
            }
        }

        return result.sorted { $0.0 < $1.0 }.prefix(maxPending).map(\.1)
    }

    /// Up to four timeline items as "08:00 Title · Title", else the day summary.
    static func summary(of day: TripDay) -> String {
        let items = day.sortedTimelineItems.prefix(4).map { item -> String in
            let title = item.title.trimmingCharacters(in: .whitespaces)
            return parseHHmm(item.time) != nil ? "\(item.time) \(title)" : title
        }
        if !items.isEmpty {
            let more = day.timelineItems.count - items.count
            return items.joined(separator: " · ") + (more > 0 ? " · +\(more) more" : "")
        }
        let s = day.summary.trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? "No plans yet. Open TravelTips to add some." : s
    }

    private static func at(_ hour: Int, on day: Date, _ cal: Calendar) -> Date? {
        cal.date(bySettingHour: hour, minute: 0, second: 0, of: day)
    }

    private static func components(_ date: Date, _ cal: Calendar) -> DateComponents {
        cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }
}

// MARK: - Scheduling

enum NotificationScheduler {
    static let enabledKey = "notificationsEnabled"

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }

    /// Replaces all pending trip notifications with a fresh plan. Does nothing
    /// beyond clearing them when the user has turned notifications off or
    /// hasn't granted permission. Never prompts for permission.
    @MainActor
    static func reschedule(context: ModelContext) async {
        let center = UNUserNotificationCenter.current()
        await clearTripNotifications(center)

        guard isEnabled else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let trips = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
        for planned in NotificationPlanner.plan(for: trips) {
            let content = UNMutableNotificationContent()
            content.title = planned.title
            content.body = planned.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: planned.fire, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: planned.id, content: content, trigger: trigger))
        }
    }

    /// Asks for permission. Returns whether notifications can be delivered.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted { return true }
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional
    }

    static func clearTripNotifications(_ center: UNUserNotificationCenter = .current()) async {
        let ids = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(NotificationPlanner.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

#if DEBUG
import SwiftUI

/// Debug-only: shows what is actually queued in UNUserNotificationCenter.
struct PendingNotificationsDebugView: View {
    @State private var lines: [String] = []
    @State private var count = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Pending trip notifications: \(count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .accessibilityIdentifier("pendingNotificationCount")
                Spacer()
                Button("Refresh") { Task { await load() } }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.primary)
            }
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSec)
            }
        }
        .task { await load() }
    }

    private func load() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(NotificationPlanner.idPrefix) }
        let dated: [(Date, UNNotificationRequest)] = requests.compactMap { r in
            guard let t = r.trigger as? UNCalendarNotificationTrigger, let d = t.nextTriggerDate() else { return nil }
            return (d, r)
        }.sorted { $0.0 < $1.0 }
        let f = DateFormatter()
        f.dateFormat = "MMM d HH:mm"
        count = requests.count
        lines = dated.prefix(3).map { "\(f.string(from: $0.0))  \($0.1.content.title) — \($0.1.content.body)" }
    }
}
#endif
