import Foundation
import SwiftData

// MARK: - Schema V1 (frozen)
//
// The exact model shape shipped in v1.0 and still on devices that haven't
// migrated. DO NOT EDIT: SwiftData identifies an existing store's version by
// hashing these definitions, so any change here makes v1.0 stores unreadable.
// Only used by the migration plan and migration tests.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Trip.self, TripDay.self, TransportInfo.self, Accommodation.self,
         Destination.self, TimelineItem.self, InfoItem.self, TaskItem.self,
         Attachment.self, PackingItem.self, PackingTag.self]
    }

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

        init(name: String, emoji: String, startDate: Date, endDate: Date, colorHex: String = "076C44") {
            self.id = UUID()
            self.name = name
            self.emoji = emoji
            self.startDate = startDate
            self.endDate = endDate
            self.colorHex = colorHex
        }
    }

    @Model
    final class TripDay {
        @Attribute(.unique) var id: UUID
        var date: Date
        var city: String
        var summary: String
        var sortOrder: Int
        var dayDone: Bool

        @Relationship(deleteRule: .cascade) var transports: [TransportInfo] = []
        @Relationship(deleteRule: .cascade) var accommodation: Accommodation?
        @Relationship(deleteRule: .cascade) var destinations: [Destination] = []
        @Relationship(deleteRule: .cascade) var timelineItems: [TimelineItem] = []

        init(date: Date, city: String, summary: String, sortOrder: Int, dayDone: Bool = false) {
            self.id = UUID()
            self.date = date
            self.city = city
            self.summary = summary
            self.sortOrder = sortOrder
            self.dayDone = dayDone
        }
    }

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

    @Model
    final class TimelineItem {
        @Attribute(.unique) var id: UUID
        var time: String
        var title: String
        var note: String?
        var address: String?
        var type: TimelineType
        var linkedId: UUID?
        var isDone: Bool
        var sortOrder: Int

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
        @Attribute(.unique) var id: UUID
        var title: String
        var isDone: Bool
        var createdAt: Date

        init(title: String) {
            self.id = UUID()
            self.title = title
            self.isDone = false
            self.createdAt = Date()
        }
    }

    @Model
    final class Attachment {
        @Attribute(.unique) var id: UUID
        var name: String
        var fileType: String
        var fileSize: String
        var localPath: String
        var linkedItemId: UUID
        var createdAt: Date

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

    @Model
    final class PackingItem {
        @Attribute(.unique) var id: UUID
        var name: String
        var tag: String?
        var quantity: Int
        var notes: String?
        var isPacked: Bool
        var isArchived: Bool
        var sortOrder: Int

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
        @Attribute(.unique) var id: UUID
        var name: String
        var sortOrder: Int

        init(name: String, sortOrder: Int = 0) {
            self.id = UUID()
            self.name = name
            self.sortOrder = sortOrder
        }
    }
}
