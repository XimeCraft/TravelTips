import Foundation
import SwiftData

// MARK: - Enums

enum TransportType: String, Codable, CaseIterable {
    case flight, drive, train, bus, ferry, other

    var icon: String {
        switch self {
        case .flight: return "✈️"
        case .drive:  return "🚗"
        case .train:  return "🚄"
        case .bus:    return "🚌"
        case .ferry:  return "⛴️"
        case .other:  return "🚀"
        }
    }

    var displayName: String { rawValue.capitalized }
}

enum DestinationType: String, Codable, CaseIterable {
    case attraction, activity, restaurant, shopping, other

    var icon: String {
        switch self {
        case .attraction:  return "🏛️"
        case .activity:    return "🎪"
        case .restaurant:  return "🍽️"
        case .shopping:    return "🛍️"
        case .other:       return "📍"
        }
    }
}

// MARK: - Trip

@Model
final class Trip {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String
    var startDate: Date
    var endDate: Date
    var colorHex: String

    @Relationship(deleteRule: .cascade) var days: [TripDay] = []
    @Relationship(deleteRule: .cascade) var infoItems: [InfoItem] = []

    init(name: String, emoji: String, startDate: Date, endDate: Date,
         colorHex: String = "076C44") {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.startDate = startDate
        self.endDate = endDate
        self.colorHex = colorHex
    }

    var sortedDays: [TripDay] {
        days.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedInfoItems: [InfoItem] {
        infoItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    var totalDays: Int { daysBetween(startDate, endDate) }
    var daysLeft: Int  { daysUntil(startDate) }
}

// MARK: - TripDay

@Model
final class TripDay {
    @Attribute(.unique) var id: UUID
    var date: Date
    var city: String
    var summary: String
    var sortOrder: Int

    @Relationship(deleteRule: .cascade) var transport: TransportInfo?
    @Relationship(deleteRule: .cascade) var accommodation: Accommodation?
    @Relationship(deleteRule: .cascade) var destinations: [Destination] = []
    @Relationship(deleteRule: .cascade) var details: [DayDetail] = []

    init(date: Date, city: String, summary: String, sortOrder: Int) {
        self.id = UUID()
        self.date = date
        self.city = city
        self.summary = summary
        self.sortOrder = sortOrder
    }

    var sortedDestinations: [Destination] {
        destinations.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedDetails: [DayDetail] {
        details.sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - TransportInfo

@Model
final class TransportInfo {
    @Attribute(.unique) var id: UUID
    var type: TransportType
    var detail: String
    var from: String
    var to: String
    var departureTime: String
    var arrivalTime: String

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

// MARK: - Accommodation

@Model
final class Accommodation {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var isCheckIn: Bool
    var isCheckOut: Bool

    init(name: String, address: String, isCheckIn: Bool = false, isCheckOut: Bool = false) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.isCheckIn = isCheckIn
        self.isCheckOut = isCheckOut
    }
}

// MARK: - Destination

@Model
final class Destination {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: DestinationType
    var time: String?
    var address: String
    var ticketPrice: String?
    var notes: String?
    var sortOrder: Int

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

// MARK: - DayDetail

@Model
final class DayDetail {
    @Attribute(.unique) var id: UUID
    var time: String
    var title: String
    var note: String?
    var isDone: Bool
    var sortOrder: Int

    init(time: String, title: String, note: String? = nil,
         isDone: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.time = time
        self.title = title
        self.note = note
        self.isDone = isDone
        self.sortOrder = sortOrder
    }
}

// MARK: - InfoItem

@Model
final class InfoItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String
    var isDone: Bool
    var sortOrder: Int

    init(title: String, details: String, isDone: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.isDone = isDone
        self.sortOrder = sortOrder
    }
}
