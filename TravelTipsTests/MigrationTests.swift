import Foundation
import SwiftData
import Testing
@testable import TravelTips

// MARK: - Day keys

struct DayKeyTests {
    let shanghai = TimeZone(identifier: "Asia/Shanghai")!
    let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    let madrid = TimeZone(identifier: "Europe/Madrid")!

    /// 2026-07-02 15:30 UTC — late evening in Shanghai, already July 3 in Tokyo.
    let lateEvening = Date(timeIntervalSince1970: 1_783_006_200)

    @Test func instantMapsToDifferentDaysPerZone() {
        #expect(DayKey.from(lateEvening, in: shanghai) == "2026-07-02")
        #expect(DayKey.from(lateEvening, in: tokyo) == "2026-07-03")
    }

    @Test func keyIsTheSameCalendarDayInEveryZone() throws {
        for tz in [shanghai, tokyo, madrid, TimeZone(identifier: "America/Los_Angeles")!] {
            let d = try #require(DayKey.date("2026-07-02", in: tz))
            #expect(DayKey.from(d, in: tz) == "2026-07-02")
            var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
            #expect(cal.startOfDay(for: d) == d)
        }
    }

    @Test func addingCrossesMonthAndYear() {
        #expect(DayKey.adding(1, to: "2026-03-31") == "2026-04-01")
        #expect(DayKey.adding(1, to: "2026-12-31") == "2027-01-01")
        #expect(DayKey.adding(-1, to: "2026-03-01") == "2026-02-28")
    }

    @Test func malformedKeyIsNil() {
        #expect(DayKey.date("") == nil)
        #expect(DayKey.date("2026-07") == nil)
    }
}

// MARK: - V1 → V2 migration

private func tempStoreURL() throws -> URL {
    let dir = FileManager.default.temporaryDirectory.appending(path: "mig-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appending(path: "default.store")
}

private func openV2(at url: URL) throws -> ModelContainer {
    let schema = Schema(versionedSchema: SchemaV2.self)
    return try ModelContainer(for: schema, migrationPlan: TravelTipsMigrationPlan.self,
                              configurations: ModelConfiguration(schema: schema, url: url))
}

@MainActor
@Suite(.serialized)
struct MigrationTests {

    @Test func syntheticV1StoreMigratesWithDayKeys() throws {
        let url = try tempStoreURL()
        let tripId: UUID, dayIds: [UUID], accId: UUID, transportId: UUID

        // Build a V1 store shaped like the user's "Japan" trip: instants at 15:30 UTC.
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let ctx = ModelContext(container)
            let base = Date(timeIntervalSince1970: 1_783_006_200)   // 2026-07-02 15:30 UTC
            let trip = SchemaV1.Trip(name: "Japan", emoji: "🇯🇵", startDate: base, endDate: base + 3 * 86400)
            ctx.insert(trip)
            var ids: [UUID] = []
            for i in 0..<4 {
                let day = SchemaV1.TripDay(date: base + Double(i) * 86400, city: "Tokyo", summary: "d\(i)", sortOrder: i)
                trip.days.append(day)
                ids.append(day.id)
            }
            let acc = SchemaV1.Accommodation(name: "Hotel", address: "addr", isCheckIn: true)
            trip.days[0].accommodation = acc
            let t = SchemaV1.TransportInfo(type: .train, detail: "N700", from: "Tokyo", to: "Kyoto",
                                           departureTime: "09:00", arrivalTime: "11:15")
            trip.days[1].transports.append(t)
            trip.days[1].timelineItems.append(SchemaV1.TimelineItem(time: "09:00", title: "Train", type: .train, linkedId: t.id))
            trip.infoItems.append(SchemaV1.InfoItem(title: "Visa", details: "none"))
            ctx.insert(SchemaV1.Attachment(name: "ticket.pdf", fileType: "pdf", fileSize: "1 KB",
                                           localPath: "attachments/x.pdf", linkedItemId: t.id))
            ctx.insert(SchemaV1.PackingItem(name: "Passport", tag: "证件"))
            try ctx.save()
            tripId = trip.id; dayIds = ids; accId = acc.id; transportId = t.id
        }

        MigrateV1toV2.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        defer { MigrateV1toV2.timeZone = .current }

        let ctx = ModelContext(try openV2(at: url))
        let trip = try #require(try ctx.fetch(FetchDescriptor<Trip>()).first)
        #expect(trip.id == tripId)
        #expect(trip.startKey == "2026-07-02")
        #expect(trip.endKey == "2026-07-05")

        let days = trip.sortedDays
        #expect(days.map(\.id) == dayIds)
        #expect(days.map(\.dayKey) == ["2026-07-02", "2026-07-03", "2026-07-04", "2026-07-05"])
        #expect(days.map(\.city) == ["Tokyo", "Tokyo", "Tokyo", "Tokyo"])
        #expect(days[0].accommodation?.id == accId)
        #expect(days[1].transports.first?.id == transportId)
        #expect(days[1].timelineItems.first?.linkedId == transportId)
        #expect(trip.infoItems.count == 1)
        #expect(try ctx.fetch(FetchDescriptor<TravelTips.Attachment>()).first?.linkedItemId == transportId)
        #expect(try ctx.fetchCount(FetchDescriptor<PackingItem>()) == 1)

        // Reading back in Tokyo now gives the same calendar days, not one day later.
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        #expect(DayKey.from(DayKey.date(trip.startKey, in: tokyo)!, in: tokyo) == "2026-07-02")
    }

    @Test func v2StoreReopensWithoutChange() throws {
        let url = try tempStoreURL()
        do {
            let ctx = ModelContext(try openV2(at: url))
            ctx.insert(Trip(name: "A", emoji: "✈️", startDate: .now, endDate: .now))
            try ctx.save()
        }
        let ctx = ModelContext(try openV2(at: url))
        #expect(try ctx.fetchCount(FetchDescriptor<Trip>()) == 1)
    }

    /// Runs against a copy of a real v1.0 store when TRAVELTIPS_STORE_FIXTURE points
    /// at a folder containing default.store(-shm,-wal). Pass it to xcodebuild as
    /// TEST_RUNNER_TRAVELTIPS_STORE_FIXTURE=<folder>. Skipped otherwise.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["TRAVELTIPS_STORE_FIXTURE"] != nil))
    func realDeviceStoreMigrates() throws {
        let fixture = URL(fileURLWithPath: ProcessInfo.processInfo.environment["TRAVELTIPS_STORE_FIXTURE"]!)
        let url = try tempStoreURL()
        for name in StoreSetup.storeFiles {
            let src = fixture.appending(path: name)
            if FileManager.default.fileExists(atPath: src.path) {
                try FileManager.default.copyItem(at: src, to: url.deletingLastPathComponent().appending(path: name))
            }
        }

        MigrateV1toV2.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        defer { MigrateV1toV2.timeZone = .current }
        let ctx = ModelContext(try openV2(at: url))

        let counts: [(String, Int)] = [
            ("Trip", try ctx.fetchCount(FetchDescriptor<Trip>())),
            ("TripDay", try ctx.fetchCount(FetchDescriptor<TripDay>())),
            ("TransportInfo", try ctx.fetchCount(FetchDescriptor<TransportInfo>())),
            ("Accommodation", try ctx.fetchCount(FetchDescriptor<Accommodation>())),
            ("Destination", try ctx.fetchCount(FetchDescriptor<Destination>())),
            ("TimelineItem", try ctx.fetchCount(FetchDescriptor<TimelineItem>())),
            ("InfoItem", try ctx.fetchCount(FetchDescriptor<InfoItem>())),
            ("Attachment", try ctx.fetchCount(FetchDescriptor<TravelTips.Attachment>())),
            ("PackingItem", try ctx.fetchCount(FetchDescriptor<PackingItem>())),
        ]
        var report = counts.map { "\($0.0)=\($0.1)" }

        let trips = try ctx.fetch(FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startKey)]))
        for trip in trips {
            let keys = trip.sortedDays.map(\.dayKey)
            report.append("TRIP \(trip.name) \(trip.startKey)..\(trip.endKey) days=\(keys.joined(separator: ","))")
            #expect(!trip.startKey.isEmpty && !trip.endKey.isEmpty)
            #expect(keys.first == trip.startKey)
            // Days stay consecutive.
            for (a, b) in zip(keys, keys.dropFirst()) { #expect(DayKey.adding(1, to: a) == b) }
        }
        #expect(try ctx.fetch(FetchDescriptor<TripDay>()).allSatisfy { !$0.dayKey.isEmpty })

        // Optional machine-readable report for comparing against the source store.
        if let out = ProcessInfo.processInfo.environment["TRAVELTIPS_MIGRATION_REPORT"] {
            try report.joined(separator: "\n").write(toFile: out, atomically: true, encoding: .utf8)
        }
    }
}
