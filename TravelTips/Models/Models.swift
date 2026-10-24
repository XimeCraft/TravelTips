import Foundation
import SwiftData

// MARK: - Enums

enum TransportType: String, Codable, CaseIterable {
    case flight, drive, train, bus, ferry, other

    var emoji: String {
        switch self {
        case .flight: return "✈️"
        case .drive:  return "🚗"
        case .train:  return "🚄"
        case .bus:    return "🚌"
        case .ferry:  return "⛴️"
        case .other:  return "🚀"
        }
    }

    var displayName: String {
        switch self {
        case .flight: return String(localized: "Flight")
        case .drive:  return String(localized: "Drive")
        case .train:  return String(localized: "Train")
        case .bus:    return String(localized: "Bus")
        case .ferry:  return String(localized: "Ferry")
        case .other:  return String(localized: "Other")
        }
    }

    var timelineType: TimelineType {
        switch self {
        case .flight: return .flight
        case .drive:  return .drive
        case .train:  return .train
        case .bus:    return .bus
        case .ferry:  return .ferry
        case .other:  return .other
        }
    }
}

enum DestinationType: String, Codable, CaseIterable {
    case attraction, activity, restaurant, shopping, other

    var timelineType: TimelineType {
        switch self {
        case .attraction: return .attraction
        case .activity:   return .activity
        case .restaurant: return .restaurant
        case .shopping:   return .other
        case .other:      return .other
        }
    }

    var displayName: String {
        switch self {
        case .attraction: return String(localized: "Attraction")
        case .activity:   return String(localized: "Activity")
        case .restaurant: return String(localized: "Restaurant")
        case .shopping:   return String(localized: "Shopping")
        case .other:      return String(localized: "Other")
        }
    }

    var emoji: String {
        switch self {
        case .attraction:  return "🏛️"
        case .activity:    return "🎪"
        case .restaurant:  return "🍽️"
        case .shopping:    return "🛍️"
        case .other:       return "📍"
        }
    }
}

enum TimelineType: String, Codable, CaseIterable {
    case flight, drive, train, bus, ferry  // → transport blue
    case hotel                             // → purple
    case attraction                        // → yellow
    case restaurant                        // → green (primary)
    case activity                          // → cyan
    case other                             // → gray

    var emoji: String {
        switch self {
        case .flight:     return "✈️"
        case .drive:      return "🚗"
        case .train:      return "🚄"
        case .bus:        return "🚌"
        case .ferry:      return "⛴️"
        case .hotel:      return "🏨"
        case .attraction: return "🏛️"
        case .restaurant: return "🍽️"
        case .activity:   return "🎪"
        case .other:      return "📝"
        }
    }

    var displayName: String {
        switch self {
        case .flight:     return String(localized: "Flight")
        case .drive:      return String(localized: "Drive")
        case .train:      return String(localized: "Train")
        case .bus:        return String(localized: "Bus")
        case .ferry:      return String(localized: "Ferry")
        case .hotel:      return String(localized: "Hotel")
        case .attraction: return String(localized: "Attraction")
        case .restaurant: return String(localized: "Restaurant")
        case .activity:   return String(localized: "Activity")
        case .other:      return String(localized: "Other")
        }
    }

    var isTransport: Bool {
        switch self {
        case .flight, .drive, .train, .bus, .ferry: return true
        default: return false
        }
    }
}

// MARK: - Day keys
//
// A calendar day is stored as "yyyy-MM-dd" (Gregorian), never as a Date. A Date
// is an instant, so its calendar day depends on the device's time zone: a day
// created at 23:30 in Shanghai shows as the next day in Tokyo. Keys are turned
// back into a Date at start of day in the *current* zone on every read, so all
// existing Calendar.current comparisons stay consistent wherever the user is.

enum DayKey {
    private static func gregorian(_ tz: TimeZone) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal
    }

    /// "yyyy-MM-dd" for the calendar day `date` falls on in `timeZone`.
    static func from(_ date: Date, in timeZone: TimeZone = .current) -> String {
        let c = gregorian(timeZone).dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 1, c.month ?? 1, c.day ?? 1)
    }

    /// Start of that day in `timeZone`, or nil if `key` is malformed.
    static func date(_ key: String, in timeZone: TimeZone = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return gregorian(timeZone).date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// The key `days` after `key`.
    static func adding(_ days: Int, to key: String) -> String? {
        let utc = TimeZone(identifier: "UTC")!
        guard let d = date(key, in: utc),
              let next = gregorian(utc).date(byAdding: .day, value: days, to: d) else { return nil }
        return from(next, in: utc)
    }
}

// MARK: - Schema V2 (current)
//
// Changes from V1:
// - Trip.startDate/endDate and TripDay.date are stored as day keys
//   (startKey/endKey/dayKey); the Date properties are now computed.
// - @Attribute(.unique) removed and every attribute has a default value
//   (CloudKit-compatible attributes; relationships are not yet optional).

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Trip.self, TripDay.self, TransportInfo.self, Accommodation.self,
         Destination.self, TimelineItem.self, InfoItem.self, TaskItem.self,
         Attachment.self, PackingItem.self, PackingTag.self]
    }

    @Model
    final class Trip {
        var id: UUID = UUID()
        var name: String = ""
        var emoji: String = "✈️"
        var startKey: String = ""
        var endKey: String = ""
        var colorHex: String = "076C44"

        @Relationship(deleteRule: .cascade) var days: [TripDay] = []
        @Relationship(deleteRule: .cascade) var infoItems: [InfoItem] = []

        init(name: String, emoji: String, startDate: Date, endDate: Date,
             colorHex: String = "076C44") {
            self.id = UUID()
            self.name = name
            self.emoji = emoji
            self.startKey = DayKey.from(startDate)
            self.endKey = DayKey.from(endDate)
            self.colorHex = colorHex
        }
    }

    @Model
    final class TripDay {
        var id: UUID = UUID()
        var dayKey: String = ""
        var city: String = ""
        var summary: String = ""
        var sortOrder: Int = 0
        var dayDone: Bool = false

        @Relationship(deleteRule: .cascade) var transports: [TransportInfo] = []
        @Relationship(deleteRule: .cascade) var accommodation: Accommodation?
        @Relationship(deleteRule: .cascade) var destinations: [Destination] = []
        @Relationship(deleteRule: .cascade) var timelineItems: [TimelineItem] = []

        init(date: Date, city: String, summary: String, sortOrder: Int, dayDone: Bool = false) {
            self.id = UUID()
            self.dayKey = DayKey.from(date)
            self.city = city
            self.summary = summary
            self.sortOrder = sortOrder
            self.dayDone = dayDone
        }
    }

    @Model
    final class TransportInfo {
        var id: UUID = UUID()
        var type: TransportType = TransportType.flight
        var detail: String = ""
        var from: String = ""
        var to: String = ""
        var departureTime: String = ""
        var arrivalTime: String = ""

        init(type: TransportType, detail: String, from: String, to: String,
             departureTime: String, arrivalTime: String) {
            self.id = UUID()
            self.type = type
            self.detail = detail
            self.from = from
            self.to = to
            self.departureTime = departureTime
            self.arrivalTime = arrivalTime
        }
    }

    @Model
    final class Accommodation {
        var id: UUID = UUID()
        var name: String = ""
        var address: String = ""
        var isCheckIn: Bool = false
        var isCheckOut: Bool = false

        init(name: String, address: String, isCheckIn: Bool = false, isCheckOut: Bool = false) {
            self.id = UUID()
            self.name = name
            self.address = address
            self.isCheckIn = isCheckIn
            self.isCheckOut = isCheckOut
        }
    }

    @Model
    final class Destination {
        var id: UUID = UUID()
        var name: String = ""
        var type: DestinationType = DestinationType.attraction
        var time: String?
        var address: String = ""
        var ticketPrice: String?
        var notes: String?
        var sortOrder: Int = 0

        init(name: String, type: DestinationType, time: String? = nil, address: String,
             ticketPrice: String? = nil, notes: String? = nil, sortOrder: Int = 0) {
            self.id = UUID()
            self.name = name
            self.type = type
            self.time = time
            self.address = address
            self.ticketPrice = ticketPrice
            self.notes = notes
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class TimelineItem {
        var id: UUID = UUID()
        var time: String = ""
        var title: String = ""
        var note: String?
        var address: String?
        var type: TimelineType = TimelineType.other
        var linkedId: UUID?
        var isDone: Bool = false
        var sortOrder: Int = 0

        init(time: String, title: String, note: String? = nil, address: String? = nil,
             type: TimelineType = .other, linkedId: UUID? = nil,
             isDone: Bool = false, sortOrder: Int = 0) {
            self.id = UUID()
            self.time = time
            self.title = title
            self.note = note
            self.address = address
            self.type = type
            self.linkedId = linkedId
            self.isDone = isDone
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class TaskItem {
        var id: UUID = UUID()
        var title: String = ""
        var isDone: Bool = false
        var createdAt: Date = Date()

        init(title: String) {
            self.id = UUID()
            self.title = title
            self.isDone = false
            self.createdAt = Date()
        }
    }

    /// Linked to any item by `linkedItemId`. Files live in Documents/attachments/.
    @Model
    final class Attachment {
        var id: UUID = UUID()
        var name: String = ""
        var fileType: String = "pdf"     // "pdf" or "image"
        var fileSize: String = ""        // display string e.g. "2.4 MB"
        var localPath: String = ""       // relative to Documents, e.g. "attachments/abc.pdf"
        var linkedItemId: UUID = UUID()
        var createdAt: Date = Date()

        init(name: String, fileType: String, fileSize: String, localPath: String, linkedItemId: UUID) {
            self.id = UUID()
            self.name = name
            self.fileType = fileType
            self.fileSize = fileSize
            self.localPath = localPath
            self.linkedItemId = linkedItemId
            self.createdAt = Date()
        }
    }

    @Model
    final class InfoItem {
        var id: UUID = UUID()
        var title: String = ""
        var details: String = ""
        var isDone: Bool = false
        var sortOrder: Int = 0

        init(title: String, details: String, isDone: Bool = false, sortOrder: Int = 0) {
            self.id = UUID()
            self.title = title
            self.details = details
            self.isDone = isDone
            self.sortOrder = sortOrder
        }
    }

    /// Global packing list, shared across trips.
    @Model
    final class PackingItem {
        var id: UUID = UUID()
        var name: String = ""
        var tag: String?            // references PackingTag.name
        var quantity: Int = 1
        var notes: String?
        var isPacked: Bool = false
        var isArchived: Bool = false
        var sortOrder: Int = 0

        init(name: String, tag: String? = nil, quantity: Int = 1,
             notes: String? = nil, isPacked: Bool = false,
             isArchived: Bool = false, sortOrder: Int = 0) {
            self.id = UUID()
            self.name = name
            self.tag = tag
            self.quantity = quantity
            self.notes = notes
            self.isPacked = isPacked
            self.isArchived = isArchived
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class PackingTag {
        var id: UUID = UUID()
        var name: String = ""
        var sortOrder: Int = 0

        init(name: String, sortOrder: Int = 0) {
            self.id = UUID()
            self.name = name
            self.sortOrder = sortOrder
        }
    }
}

// MARK: - Current model names

typealias Trip = SchemaV2.Trip
typealias TripDay = SchemaV2.TripDay
typealias TransportInfo = SchemaV2.TransportInfo
typealias Accommodation = SchemaV2.Accommodation
typealias Destination = SchemaV2.Destination
typealias TimelineItem = SchemaV2.TimelineItem
typealias TaskItem = SchemaV2.TaskItem
typealias Attachment = SchemaV2.Attachment
typealias InfoItem = SchemaV2.InfoItem
typealias PackingItem = SchemaV2.PackingItem
typealias PackingTag = SchemaV2.PackingTag

// MARK: - Trip helpers

extension Trip {
    /// Start of the first day in the current time zone. Setting stores the day key.
    var startDate: Date {
        get { DayKey.date(startKey) ?? .distantPast }
        set { startKey = DayKey.from(newValue) }
    }

    /// Start of the last day in the current time zone. Setting stores the day key.
    var endDate: Date {
        get { DayKey.date(endKey) ?? .distantPast }
        set { endKey = DayKey.from(newValue) }
    }

    var sortedDays: [TripDay] {
        days.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedInfoItems: [InfoItem] {
        infoItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    var totalDays: Int { daysBetween(startDate, endDate) }
    var daysLeft: Int  { daysUntil(startDate) }

    // MARK: Cross-day linked item lookup

    func findTransport(linkedId: UUID) -> (TransportInfo, TripDay)? {
        for day in days {
            for t in day.transports where t.id == linkedId {
                return (t, day)
            }
        }
        return nil
    }

    func findAccommodation(linkedId: UUID) -> Accommodation? {
        for day in days {
            if day.accommodation?.id == linkedId { return day.accommodation }
        }
        return nil
    }

    func findDestination(linkedId: UUID) -> Destination? {
        for day in days {
            for d in day.destinations where d.id == linkedId { return d }
        }
        return nil
    }
}

// MARK: - TripDay helpers

extension TripDay {
    /// Start of this day in the current time zone. Setting stores the day key.
    var date: Date {
        get { DayKey.date(dayKey) ?? .distantPast }
        set { dayKey = DayKey.from(newValue) }
    }

    var sortedDestinations: [Destination] {
        destinations.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Items with a readable time first, in time order; items without one
    /// ("--:--", "All Day", free text) after them. Ties keep insertion order.
    var sortedTimelineItems: [TimelineItem] {
        timelineItems.sorted { a, b in
            switch (parseHHmm(a.time), parseHHmm(b.time)) {
            case let (ta?, tb?) where ta != tb: return ta < tb
            case (_?, nil):                     return true
            case (nil, _?):                     return false
            default:                            return a.sortOrder < b.sortOrder
            }
        }
    }

    var firstTransport: TransportInfo? {
        transports.first
    }
}
