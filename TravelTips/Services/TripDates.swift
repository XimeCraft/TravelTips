import Foundation
import SwiftData

// MARK: - Changing a trip's date range
//
// Extending adds empty days; shrinking deletes the days that fall outside the
// new range together with everything on them. The UI asks for confirmation
// first whenever a removed day has content (see `daysToRemove`).

extension TripDay {
    /// True if deleting this day would lose anything the user entered.
    var hasContent: Bool {
        !transports.isEmpty || accommodation != nil || !destinations.isEmpty
            || !timelineItems.isEmpty
            || !city.trimmingCharacters(in: .whitespaces).isEmpty
            || !summary.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Short description of what is on the day, e.g. "1 transport, 2 places".
    var contentSummary: String {
        var parts: [String] = []
        if !transports.isEmpty { parts.append("\(transports.count) transport") }
        if accommodation != nil { parts.append("1 hotel night") }
        if !destinations.isEmpty { parts.append("\(destinations.count) place\(destinations.count > 1 ? "s" : "")") }
        let manual = timelineItems.filter { $0.linkedId == nil }.count
        if manual > 0 { parts.append("\(manual) timeline item\(manual > 1 ? "s" : "")") }
        if parts.isEmpty { parts.append("notes") }
        return parts.joined(separator: ", ")
    }
}

enum TripDates {

    /// Calendar days from `start` through `end`, each at start of day.
    static func dayStarts(from start: Date, to end: Date, calendar: Calendar = .current) -> [Date] {
        var result: [Date] = []
        var current = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while current <= last {
            result.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return result
    }

    /// Days of `trip` that fall outside `start...end`, sorted by date.
    static func daysToRemove(from trip: Trip, start: Date, end: Date, calendar: Calendar = .current) -> [TripDay] {
        let keep = Set(dayStarts(from: start, to: end, calendar: calendar))
        return trip.sortedDays.filter { !keep.contains(calendar.startOfDay(for: $0.date)) }
    }

    /// Applies the new range: removes days outside it, adds missing days, renumbers.
    static func apply(to trip: Trip, start: Date, end: Date,
                      context: ModelContext, calendar: Calendar = .current) {
        let removed = daysToRemove(from: trip, start: start, end: end, calendar: calendar)
        let removedIds = Set(removed.map(\.id))
        // Must be computed before anything is deleted.
        let stays = hotelStays(in: trip)

        // 1. Transport and places on removed days: their attachments, and any
        //    linked timeline item that lives on a kept day.
        var lostOwners = Set<UUID>()
        for day in removed {
            day.transports.forEach { lostOwners.insert($0.id) }
            day.destinations.forEach { lostOwners.insert($0.id) }
        }
        for day in trip.days where !removedIds.contains(day.id) {
            removeTimelineItems(in: day, context: context) { lostOwners.contains($0) }
        }
        AttachmentStore.deleteAll(linkedTo: lostOwners, context: context)

        // 2. Hotel stays whose anchor (first) night is removed.
        for stay in stays where removedIds.contains(stay.nights[0].day.id) {
            let survivor = stay.nights.first { !removedIds.contains($0.day.id) }
            if let newAnchor = survivor?.acc {
                newAnchor.isCheckIn = true
                for day in trip.days {
                    for item in day.timelineItems where item.linkedId == stay.anchorId {
                        item.linkedId = newAnchor.id
                    }
                }
                AttachmentStore.relink(from: stay.anchorId, to: newAnchor.id, context: context)
            } else {
                for day in trip.days where !removedIds.contains(day.id) {
                    removeTimelineItems(in: day, context: context) { $0 == stay.anchorId }
                }
                AttachmentStore.deleteAll(linkedTo: [stay.anchorId], context: context)
            }
        }

        // 3. Delete the days (cascade removes their transports, nights, places, timeline).
        trip.days.removeAll { removedIds.contains($0.id) }
        removed.forEach { context.delete($0) }

        // 4. Add missing days, renumber, update the trip's range.
        let existing = Set(trip.days.map { calendar.startOfDay(for: $0.date) })
        for date in dayStarts(from: start, to: end, calendar: calendar) where !existing.contains(date) {
            trip.days.append(TripDay(date: date, city: "", summary: "", sortOrder: 0))
        }
        for (i, day) in trip.days.sorted(by: { $0.date < $1.date }).enumerated() {
            day.sortOrder = i
        }
        trip.startDate = calendar.startOfDay(for: start)
        trip.endDate = calendar.startOfDay(for: end)
    }

    // MARK: Helpers

    private struct Stay {
        let nights: [(day: TripDay, acc: Accommodation)]
        var anchorId: UUID { nights[0].acc.id }
    }

    /// Consecutive nights at the same hotel, grouped the same way as AccommodationTab.
    private static func hotelStays(in trip: Trip) -> [Stay] {
        var stays: [[(day: TripDay, acc: Accommodation)]] = []
        var previousName: String? = nil
        for day in trip.sortedDays {
            guard let acc = day.accommodation else { previousName = nil; continue }
            if acc.name == previousName, !stays.isEmpty {
                stays[stays.count - 1].append((day, acc))
            } else {
                stays.append([(day, acc)])
            }
            previousName = acc.name
        }
        return stays.map(Stay.init)
    }

    private static func removeTimelineItems(in day: TripDay, context: ModelContext,
                                            where linkedTo: (UUID) -> Bool) {
        let doomed = day.timelineItems.filter { item in item.linkedId.map(linkedTo) ?? false }
        guard !doomed.isEmpty else { return }
        let ids = Set(doomed.map(\.id))
        day.timelineItems.removeAll { ids.contains($0.id) }
        doomed.forEach { context.delete($0) }
    }
}
