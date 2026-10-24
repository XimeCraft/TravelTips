//
//  TravelTipsTests.swift
//  TravelTipsTests
//
//  Created by 孟晓 on 2026/2/22.
//

import Foundation
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
