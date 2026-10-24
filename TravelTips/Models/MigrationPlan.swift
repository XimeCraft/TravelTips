import Foundation
import SwiftData

// MARK: - Migration plan

enum TravelTipsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] { [MigrateV1toV2.stage] }
}

/// V1 stored trip and day dates as instants; V2 stores calendar-day keys.
///
/// Each instant is read as a calendar day in `timeZone` (the device's zone when
/// the migration runs). That matches what the user saw when they created the
/// data as long as they migrate in the zone they planned in.
enum MigrateV1toV2 {
    enum Failure: LocalizedError {
        case missingKey(entity: String, id: UUID)
        var errorDescription: String? {
            switch self {
            case .missingKey(let entity, let id): return "Migration found no date for \(entity) \(id)."
            }
        }
    }

    /// Overridable by tests.
    static var timeZone: TimeZone = .current

    // Carried from willMigrate (V1 context) to didMigrate (V2 context).
    private static var tripKeys: [UUID: (start: String, end: String)] = [:]
    private static var dayKeys: [UUID: String] = [:]

    static let stage = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            tripKeys = [:]
            dayKeys = [:]
            for trip in try context.fetch(FetchDescriptor<SchemaV1.Trip>()) {
                tripKeys[trip.id] = (DayKey.from(trip.startDate, in: timeZone),
                                     DayKey.from(trip.endDate, in: timeZone))
            }
            for day in try context.fetch(FetchDescriptor<SchemaV1.TripDay>()) {
                dayKeys[day.id] = DayKey.from(day.date, in: timeZone)
            }
        },
        didMigrate: { context in
            defer { tripKeys = [:]; dayKeys = [:] }
            for trip in try context.fetch(FetchDescriptor<SchemaV2.Trip>()) {
                guard let keys = tripKeys[trip.id] else { throw Failure.missingKey(entity: "Trip", id: trip.id) }
                trip.startKey = keys.start
                trip.endKey = keys.end
            }
            for day in try context.fetch(FetchDescriptor<SchemaV2.TripDay>()) {
                guard let key = dayKeys[day.id] else { throw Failure.missingKey(entity: "TripDay", id: day.id) }
                day.dayKey = key
            }
            try context.save()
        }
    )
}
