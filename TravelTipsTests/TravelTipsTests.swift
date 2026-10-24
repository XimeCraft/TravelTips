//
//  TravelTipsTests.swift
//  TravelTipsTests
//
//  Created by 孟晓 on 2026/2/22.
//

import Foundation
import SwiftUI
import SwiftData
import Testing
@testable import TravelTips

@MainActor
func makeContext() throws -> ModelContext {
    let schema = Schema([
        Trip.self, TripDay.self, TransportInfo.self, Accommodation.self,
        Destination.self, TimelineItem.self, InfoItem.self, TaskItem.self,
        TravelTips.Attachment.self, PackingItem.self, PackingTag.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return ModelContext(try ModelContainer(for: schema, configurations: config))
}

@MainActor
private func addAttachment(linkedTo id: UUID, context: ModelContext) throws -> TravelTips.Attachment {
    let dir = localURL(for: "attachments")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let path = "attachments/test-\(UUID().uuidString).txt"
    try Data("x".utf8).write(to: localURL(for: path))
    let att = TravelTips.Attachment(name: "t.txt", fileType: "pdf", fileSize: "1 B", localPath: path, linkedItemId: id)
    context.insert(att)
    return att
}

private func fileExists(_ att: TravelTips.Attachment) -> Bool {
    FileManager.default.fileExists(atPath: localURL(for: att.localPath).path)
}

@MainActor
struct AttachmentStoreTests {

    @Test func deleteAllRemovesOnlyMatchingRecordsAndFiles() throws {
        let ctx = try makeContext()
        let target = UUID(), other = UUID()
        let a = try addAttachment(linkedTo: target, context: ctx)
        let b = try addAttachment(linkedTo: other, context: ctx)

        AttachmentStore.deleteAll(linkedTo: [target], context: ctx)
        try ctx.save()

        let remaining = try ctx.fetch(FetchDescriptor<TravelTips.Attachment>())
        #expect(remaining.map(\.linkedItemId) == [other])
        #expect(!fileExists(a))
        #expect(fileExists(b))
        AttachmentStore.deleteFile(for: b)
    }

    @Test func relinkMovesAttachmentsToNewOwner() throws {
        let ctx = try makeContext()
        let oldId = UUID(), newId = UUID()
        let a = try addAttachment(linkedTo: oldId, context: ctx)

        AttachmentStore.relink(from: oldId, to: newId, context: ctx)

        #expect(a.linkedItemId == newId)
        #expect(fileExists(a))
        AttachmentStore.deleteFile(for: a)
    }

    @Test func ownerIdsCoversEveryAttachableChild() throws {
        let ctx = try makeContext()
        let trip = Trip(name: "T", emoji: "✈️", startDate: .now, endDate: .now)
        let day = TripDay(date: .now, city: "", summary: "", sortOrder: 0)
        let t = TransportInfo(type: .flight, detail: "", from: "A", to: "B", departureTime: "", arrivalTime: "")
        let d = Destination(name: "P", type: .attraction, address: "")
        let acc = Accommodation(name: "H", address: "")
        let info = InfoItem(title: "I", details: "")
        ctx.insert(trip)
        trip.days.append(day)
        day.transports.append(t)
        day.destinations.append(d)
        day.accommodation = acc
        trip.infoItems.append(info)

        #expect(AttachmentStore.ownerIds(in: trip) == [t.id, d.id, acc.id, info.id])
    }
}

struct TimeParsingTests {

    @Test(arguments: [
        ("08:00", 480), ("8:05", 485), ("0805", 485), ("23:59", 1439), ("00:00", 0),
        ("08：30", 510), (" 09:15 ", 555), ("10:30-12:00", 630), ("12:30-13:00", 750),
    ])
    func parsesValidTimes(input: String, minutes: Int) {
        #expect(parseHHmm(input) == minutes)
    }

    @Test(arguments: ["", "--:--", "All Day", "24:00", "12:60", "abc", "9"])
    func rejectsNonTimes(input: String) {
        #expect(parseHHmm(input) == nil)
    }

    @Test func nilInputIsNil() {
        #expect(parseHHmm(nil) == nil)
    }

    @Test func exactRejectsTrailingText() {
        #expect(exactHHmm("09:00") == 540)
        #expect(exactHHmm("09:00 sharp") == nil)
        #expect(exactHHmm("10:30-12:00") == nil)
    }

    @Test func formatsZeroPadded() {
        #expect(formatHHmm(0) == "00:00")
        #expect(formatHHmm(485) == "08:05")
        #expect(formatHHmm(1439) == "23:59")
    }
}

@MainActor
struct TimelineSortTests {

    @Test func timedItemsFirstInTimeOrderThenUntimedByInsertion() throws {
        let ctx = try makeContext()
        let day = TripDay(date: .now, city: "", summary: "", sortOrder: 0)
        ctx.insert(day)
        let specs: [(String, String)] = [
            ("--:--", "checkout"), ("14:30", "museum"), ("All Day", "beach"),
            ("08:00", "flight"), ("10:30-12:00", "tour"), ("08:00", "breakfast"),
        ]
        for (i, (time, title)) in specs.enumerated() {
            day.timelineItems.append(TimelineItem(time: time, title: title, sortOrder: i))
        }

        #expect(day.sortedTimelineItems.map(\.title) ==
                ["flight", "breakfast", "tour", "museum", "checkout", "beach"])
    }
}

@MainActor
struct TripDatesTests {
    let cal = Calendar.current

    func d(_ day: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 3, day: day))! }

    /// Trip Mar 10–14 with a hotel Mar 10–12 (3 nights) and a flight on Mar 14.
    func makeTrip(_ ctx: ModelContext) -> (Trip, TransportInfo, Accommodation) {
        let trip = Trip(name: "T", emoji: "✈️", startDate: d(10), endDate: d(14))
        ctx.insert(trip)
        for (i, date) in TripDates.dayStarts(from: d(10), to: d(14)).enumerated() {
            trip.days.append(TripDay(date: date, city: "", summary: "", sortOrder: i))
        }
        let days = trip.sortedDays
        var anchor: Accommodation!
        for i in 0..<3 {
            let acc = Accommodation(name: "Hotel", address: "", isCheckIn: i == 0)
            days[i].accommodation = acc
            if i == 0 { anchor = acc }
        }
        days[0].timelineItems.append(TimelineItem(time: "--:--", title: "Check-in", type: .hotel, linkedId: anchor.id))
        days[3].timelineItems.append(TimelineItem(time: "--:--", title: "Check-out", type: .hotel, linkedId: anchor.id))
        let flight = TransportInfo(type: .flight, detail: "", from: "A", to: "B", departureTime: "08:00", arrivalTime: "")
        days[4].transports.append(flight)
        days[4].timelineItems.append(TimelineItem(time: "08:00", title: "A → B", type: .flight, linkedId: flight.id))
        return (trip, flight, anchor)
    }

    @Test func dayStartsIsInclusive() {
        #expect(TripDates.dayStarts(from: d(10), to: d(14)).count == 5)
        #expect(TripDates.dayStarts(from: d(10), to: d(10)).count == 1)
    }

    @Test func extendAddsEmptyDaysAndRenumbers() throws {
        let ctx = try makeContext()
        let (trip, _, _) = makeTrip(ctx)
        TripDates.apply(to: trip, start: d(8), end: d(16), context: ctx)

        let days = trip.sortedDays
        #expect(days.count == 9)
        #expect(days.map(\.sortOrder) == Array(0..<9))
        #expect(cal.isDate(days[0].date, inSameDayAs: d(8)))
        #expect(!days[0].hasContent)
        #expect(days[2].accommodation?.name == "Hotel")
        #expect(cal.isDate(trip.startDate, inSameDayAs: d(8)))
        #expect(cal.isDate(trip.endDate, inSameDayAs: d(16)))
    }

    @Test func shrinkingEndRemovesFlightAndItsAttachments() throws {
        let ctx = try makeContext()
        let (trip, flight, _) = makeTrip(ctx)
        let att = TravelTips.Attachment(name: "t", fileType: "pdf", fileSize: "", localPath: "attachments/none", linkedItemId: flight.id)
        ctx.insert(att)

        #expect(TripDates.daysToRemove(from: trip, start: d(10), end: d(13)).map(\.hasContent) == [true])
        TripDates.apply(to: trip, start: d(10), end: d(13), context: ctx)
        try ctx.save()

        #expect(trip.days.count == 4)
        #expect(trip.findTransport(linkedId: flight.id) == nil)
        #expect(try ctx.fetch(FetchDescriptor<TravelTips.Attachment>()).isEmpty)
    }

    @Test func shrinkingStartReanchorsHotelStay() throws {
        let ctx = try makeContext()
        let (trip, _, oldAnchor) = makeTrip(ctx)
        let oldId = oldAnchor.id
        let att = TravelTips.Attachment(name: "t", fileType: "pdf", fileSize: "", localPath: "attachments/none", linkedItemId: oldId)
        ctx.insert(att)

        TripDates.apply(to: trip, start: d(11), end: d(14), context: ctx)

        let days = trip.sortedDays
        let newAnchor = try #require(days[0].accommodation)
        #expect(newAnchor.id != oldId)
        #expect(newAnchor.isCheckIn)
        // Check-out on Mar 13 now points at the surviving first night.
        let checkout = try #require(days[2].timelineItems.first { $0.title == "Check-out" })
        #expect(checkout.linkedId == newAnchor.id)
        #expect(att.linkedItemId == newAnchor.id)
    }

    @Test func removingWholeStayDropsItsTimelineAndAttachments() throws {
        let ctx = try makeContext()
        let (trip, _, anchor) = makeTrip(ctx)
        ctx.insert(TravelTips.Attachment(name: "t", fileType: "pdf", fileSize: "", localPath: "attachments/none", linkedItemId: anchor.id))

        TripDates.apply(to: trip, start: d(13), end: d(14), context: ctx)
        try ctx.save()

        let days = trip.sortedDays
        #expect(days.count == 2)
        #expect(days[0].timelineItems.allSatisfy { $0.type != .hotel })   // check-out gone
        #expect(try ctx.fetch(FetchDescriptor<TravelTips.Attachment>()).isEmpty)
        #expect(days[1].transports.count == 1)                            // flight kept
    }
}

@MainActor
struct TodayIndexTests {
    let cal = Calendar.current
    func d(_ day: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 15))! }

    func trip(_ ctx: ModelContext) -> Trip {
        let t = Trip(name: "T", emoji: "✈️", startDate: d(20), endDate: d(23))
        ctx.insert(t)
        for (i, date) in TripDates.dayStarts(from: d(20), to: d(23)).enumerated() {
            t.days.append(TripDay(date: date, city: "", summary: "", sortOrder: i))
        }
        return t
    }

    @Test func findsTodayInsideTrip() throws {
        let t = trip(try makeContext())
        #expect(t.todayIndex(now: d(20)) == 0)
        #expect(t.todayIndex(now: d(22)) == 2)
        #expect(t.todayIndex(now: d(23)) == 3)
    }

    @Test func nilOutsideTrip() throws {
        let t = trip(try makeContext())
        #expect(t.todayIndex(now: d(19)) == nil)
        #expect(t.todayIndex(now: d(24)) == nil)
    }
}

@MainActor
struct NotificationPlannerTests {
    let cal = Calendar.current
    func at(_ day: Int, _ hour: Int, month: Int = 11) -> Date {
        cal.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    func makeTrip(_ ctx: ModelContext, name: String = "Spain", from: Int = 10, days: Int = 3) -> Trip {
        let t = Trip(name: name, emoji: "🇪🇸", startDate: at(from, 0), endDate: at(from + days - 1, 0))
        ctx.insert(t)
        for (i, date) in TripDates.dayStarts(from: t.startDate, to: t.endDate).enumerated() {
            t.days.append(TripDay(date: date, city: i == 0 ? "Barcelona" : "", summary: "", sortOrder: i))
        }
        return t
    }

    @Test func beforeTripPlansEveAndEveryMorning() throws {
        let trip = makeTrip(try makeContext())
        let plan = NotificationPlanner.plan(for: [trip], now: at(1, 12))

        #expect(plan.count == 4)
        #expect(plan[0].title == "🇪🇸 Spain starts tomorrow")
        #expect(plan[0].fire.day == 9 && plan[0].fire.hour == 20)
        #expect(plan[1].title == "🇪🇸 Day 1 · Barcelona")
        #expect(plan[1].fire.day == 10 && plan[1].fire.hour == 8)
        #expect(plan[2].title == "🇪🇸 Day 2 of Spain")
        #expect(plan[3].fire.day == 12)
        #expect(Set(plan.map(\.id)).count == 4)
        #expect(plan.allSatisfy { $0.id.hasPrefix(NotificationPlanner.idPrefix) })
    }

    @Test func pastTimesAreSkipped() throws {
        let trip = makeTrip(try makeContext())
        // Day 2, 09:00: eve, day 1 and day 2 mornings are past.
        let plan = NotificationPlanner.plan(for: [trip], now: at(11, 9))
        #expect(plan.map { $0.fire.day } == [12])
        #expect(NotificationPlanner.plan(for: [trip], now: at(20, 9)).isEmpty)
    }

    @Test func cappedAndNearestFirst() throws {
        let ctx = try makeContext()
        let long = makeTrip(ctx, name: "Long", from: 1, days: 30)
        let soon = makeTrip(ctx, name: "Soon", from: 1, days: 30)
        let plan = NotificationPlanner.plan(for: [long, soon], now: at(1, 0, month: 10))
        #expect(plan.count == NotificationPlanner.maxPending)
        // Sorted by fire time.
        let dates = plan.compactMap { cal.date(from: $0.fire) }
        #expect(dates == dates.sorted())
    }

    @Test func summaryListsTimedItemsFirstAndCountsTheRest() throws {
        let ctx = try makeContext()
        let day = TripDay(date: .now, city: "", summary: "Rest day", sortOrder: 0)
        ctx.insert(day)
        #expect(NotificationPlanner.summary(of: day) == "Rest day")

        for (i, (time, title)) in [("--:--", "Check-out"), ("14:30", "Museum"), ("08:00", "Flight"),
                                   ("10:30-12:00", "Tour"), ("18:00", "Dinner")].enumerated() {
            day.timelineItems.append(TimelineItem(time: time, title: title, sortOrder: i))
        }
        #expect(NotificationPlanner.summary(of: day)
                == "08:00 Flight · 10:30-12:00 Tour · 14:30 Museum · 18:00 Dinner · +1 more")
    }
}

@MainActor
struct TripExportTests {
    func makeSpain(_ ctx: ModelContext) -> Trip {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2026, month: 10, day: 20))!
        let trip = Trip(name: "Spain", emoji: "🇪🇸", startDate: start, endDate: start + 2 * 86400, colorHex: "2196F3")
        ctx.insert(trip)
        for (i, date) in TripDates.dayStarts(from: trip.startDate, to: trip.endDate).enumerated() {
            trip.days.append(TripDay(date: date, city: ["Barcelona", "Barcelona", "Seville"][i],
                                     summary: i == 0 ? "Gaudí | day" : "", sortOrder: i))
        }
        let days = trip.sortedDays
        let flight = TransportInfo(type: .flight, detail: "VY6201", from: "Geneva", to: "Barcelona",
                                   departureTime: "08:05", arrivalTime: "09:45")
        days[0].transports.append(flight)
        days[0].timelineItems.append(TimelineItem(time: "08:05", title: "Geneva → Barcelona", type: .flight, linkedId: flight.id, sortOrder: 0))
        days[0].timelineItems.append(TimelineItem(time: "14:30", title: "Sagrada Família", address: "C/ de Mallorca 401", sortOrder: 1))
        days[0].timelineItems.append(TimelineItem(time: "--:--", title: "Check-in · Hotel <Arts>", isDone: true, sortOrder: 2))
        days[0].destinations.append(Destination(name: "Sagrada Família", type: .attraction, time: "14:30-16:00",
                                                address: "C/ de Mallorca 401", ticketPrice: "€36", notes: "Tower tickets"))
        days[0].accommodation = Accommodation(name: "Hotel Arts", address: "Marina 19", isCheckIn: true)
        days[1].accommodation = Accommodation(name: "Hotel Arts", address: "Marina 19")
        trip.infoItems.append(InfoItem(title: "Passport", details: "E12345678"))
        return trip
    }

    @Test func documentHasTablesAndDaysButNoInfo() throws {
        let doc = TripExport.document(for: makeSpain(try makeContext()))
        #expect(doc.title == "🇪🇸 Spain")
        #expect(doc.glance.rows.count == 3)
        #expect(doc.glance.rows[0][0] == "D1" && doc.glance.rows[0][2] == "Barcelona")
        let transport = try #require(doc.transport)
        #expect(transport.rows == [[doc.glance.rows[0][1], "✈️ Flight", "Geneva → Barcelona", "08:05", "09:45", "VY6201"]])
        let hotels = try #require(doc.hotels)
        #expect(hotels.rows.count == 1)
        #expect(hotels.rows[0][0] == "Hotel Arts" && hotels.rows[0][3] == "2")
        #expect(doc.days[0].timeline.map(\.time) == ["08:05", "14:30", nil])
        #expect(doc.days[0].timeline[2].done)
        #expect(doc.days[0].places.first?.details.contains("Ticket €36") == true)
        #expect(doc.days[2].timeline.isEmpty)

        let md = TripExport.markdown(doc)
        #expect(!md.contains("E12345678") && !md.contains("Passport"))
    }

    @Test func markdownStructure() throws {
        let md = TripExport.markdown(TripExport.document(for: makeSpain(try makeContext())))
        #expect(md.hasPrefix("# 🇪🇸 Spain\n"))
        #expect(md.contains("## Itinerary at a Glance"))
        #expect(md.contains("| Day | Date | City | Plan |"))
        #expect(md.contains("Gaudí \\| day"))                 // pipes escaped inside tables
        #expect(md.contains("## Transport") && md.contains("## Hotels"))
        #expect(md.contains("- **08:05** Geneva → Barcelona"))
        #expect(md.contains("  - 📍 C/ de Mallorca 401"))
        #expect(md.contains("- [x] Check-in · Hotel <Arts>"))
        #expect(md.contains("- **Sagrada Família** · 🏛️ Attraction · 14:30-16:00 · Ticket €36"))
    }

    @Test func htmlEscapesAndPdfRenders() throws {
        let trip = makeSpain(try makeContext())
        let html = TripExport.html(TripExport.document(for: trip))
        #expect(html.contains("Hotel &lt;Arts&gt;"))
        #expect(!html.contains("Hotel <Arts>"))
        #expect(html.contains("#2196F3"))

        let pdf = TripExport.pdf(html: html, footer: "🇪🇸 Spain")
        #expect(pdf.count > 5_000)
        #expect(String(decoding: pdf.prefix(5), as: UTF8.self) == "%PDF-")
        if let out = ProcessInfo.processInfo.environment["TRAVELTIPS_EXPORT_DIR"] {
            try pdf.write(to: URL(fileURLWithPath: out).appending(path: "sample.pdf"))
            try TripExport.markdown(TripExport.document(for: trip)).write(
                to: URL(fileURLWithPath: out).appending(path: "sample.md"), atomically: true, encoding: .utf8)
        }
    }

    /// Exports every trip from a copy of a real store (TRAVELTIPS_EXPORT_STORE = folder
    /// with default.store*) into TRAVELTIPS_EXPORT_DIR. Skipped unless both are set.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["TRAVELTIPS_EXPORT_STORE"] != nil
                   && ProcessInfo.processInfo.environment["TRAVELTIPS_EXPORT_DIR"] != nil))
    func exportRealStore() throws {
        let env = ProcessInfo.processInfo.environment
        let src = URL(fileURLWithPath: env["TRAVELTIPS_EXPORT_STORE"]!)
        let dir = FileManager.default.temporaryDirectory.appending(path: "export-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for name in StoreSetup.storeFiles where FileManager.default.fileExists(atPath: src.appending(path: name).path) {
            try FileManager.default.copyItem(at: src.appending(path: name), to: dir.appending(path: name))
        }
        let schema = Schema(versionedSchema: SchemaV2.self)
        let container = try ModelContainer(for: schema, migrationPlan: TravelTipsMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: schema, url: dir.appending(path: "default.store")))
        let out = URL(fileURLWithPath: env["TRAVELTIPS_EXPORT_DIR"]!)
        for trip in try ModelContext(container).fetch(FetchDescriptor<Trip>()) {
            let doc = TripExport.document(for: trip)
            try TripExport.pdf(html: TripExport.html(doc), footer: trip.name)
                .write(to: out.appending(path: TripExport.fileName(for: trip, ext: "pdf")))
            try TripExport.markdown(doc).write(to: out.appending(path: TripExport.fileName(for: trip, ext: "md")),
                                               atomically: true, encoding: .utf8)
        }
    }

    @Test func fileNameStripsUnsafeCharacters() throws {
        let ctx = try makeContext()
        let t = Trip(name: "Paris/Rome: 2026?", emoji: "🇫🇷", startDate: .now, endDate: .now)
        ctx.insert(t)
        #expect(TripExport.fileName(for: t, ext: "pdf") == "ParisRome 2026.pdf")
    }
}

@MainActor
struct PackingResetTests {
    @Test func clearsPackedButLeavesArchivedAndDetails() throws {
        let ctx = try makeContext()
        let a = PackingItem(name: "Passport", tag: "证件", quantity: 1, notes: "in bag", isPacked: true)
        let b = PackingItem(name: "Socks", quantity: 5, isPacked: false)
        let c = PackingItem(name: "Old charger", isPacked: true, isArchived: true)
        [a, b, c].forEach(ctx.insert)

        resetPacked([a, b, c])

        #expect(!a.isPacked && !b.isPacked)
        #expect(c.isPacked)                      // archived: untouched
        #expect(a.notes == "in bag" && a.tag == "证件" && b.quantity == 5)
    }
}

@MainActor
struct TripShiftTests {
    let cal = Calendar.current
    func d(_ day: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 3, day: day))! }

    @Test func offsetOnlyWhenLengthUnchanged() throws {
        let ctx = try makeContext()
        let (trip, _, _) = TripDatesTests().makeTrip(ctx)          // Mar 10–14, 5 days
        #expect(TripDates.shiftOffset(for: trip, start: d(12), end: d(16)) == 2)
        #expect(TripDates.shiftOffset(for: trip, start: d(7), end: d(11)) == -3)
        #expect(TripDates.shiftOffset(for: trip, start: d(10), end: d(14)) == nil)   // unchanged
        #expect(TripDates.shiftOffset(for: trip, start: d(10), end: d(16)) == nil)   // resized
    }

    @Test func shiftMovesEveryDayAndKeepsContent() throws {
        let ctx = try makeContext()
        let (trip, flight, anchor) = TripDatesTests().makeTrip(ctx)
        let before = trip.sortedDays.map { ($0.id, $0.dayKey) }

        TripDates.shift(trip, byDays: 30)   // crosses into April

        #expect(trip.startKey == "2026-04-09")
        #expect(trip.endKey == "2026-04-13")
        let after = trip.sortedDays
        #expect(after.map(\.id) == before.map(\.0))
        #expect(after.map(\.dayKey) == ["2026-04-09", "2026-04-10", "2026-04-11", "2026-04-12", "2026-04-13"])
        #expect(after[4].transports.first?.id == flight.id)
        #expect(after[0].accommodation?.id == anchor.id)
        #expect(after[3].timelineItems.contains { $0.title == "Check-out" })
    }
}

struct TripColorTests {
    @Test func customColorsDedupeSkipPresetsAndCap() {
        var raw = ""
        raw = CustomTripColors.adding("FF8800", to: raw)
        raw = CustomTripColors.adding("123456", to: raw)
        raw = CustomTripColors.adding("FF8800", to: raw)          // moves to front, no duplicate
        raw = CustomTripColors.adding(tripColorPresets[1], to: raw) // presets are not stored
        #expect(CustomTripColors.load(raw) == ["FF8800", "123456"])
        for i in 0..<20 { raw = CustomTripColors.adding(String(format: "0000%02X", i), to: raw) }
        #expect(CustomTripColors.load(raw).count == CustomTripColors.limit)
        #expect(CustomTripColors.load(CustomTripColors.removing("000013", from: raw)).contains("000013") == false)
    }

    @Test func hexRoundTripsThroughColor() {
        #expect(HexColor.hex(from: Color(hex: "2196F3")) == "2196F3")
        #expect(HexColor.hex(from: Color(hex: "000000")) == "000000")
    }

    @Test func luminanceDrivesReadableText() {
        #expect(HexColor.luminance("FFFFFF") > 0.99)
        #expect(HexColor.luminance("000000") < 0.01)
        #expect(HexColor.luminance("FFE082") > 0.5)    // pale yellow → dark text, darkened tint
        #expect(HexColor.luminance("076C44") < 0.45)   // app green → white text
    }
}
