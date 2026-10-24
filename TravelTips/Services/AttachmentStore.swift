import Foundation
import SwiftData

// MARK: - AttachmentStore
//
// Attachments are linked to their owner only by `linkedItemId: UUID`, so SwiftData
// cascade rules never reach them. Every code path that deletes an owner (or
// replaces its id) must go through here, or the record and its file are orphaned.

enum AttachmentStore {

    /// Deletes every attachment linked to any of `ids`, including its file on disk.
    static func deleteAll(linkedTo ids: Set<UUID>, context: ModelContext) {
        guard !ids.isEmpty else { return }
        for att in fetchAll(context) where ids.contains(att.linkedItemId) {
            deleteFile(for: att)
            context.delete(att)
        }
    }

    /// Re-points attachments from `oldId` to `newId`. Used when an owner is
    /// recreated with a new id (e.g. editing a hotel rebuilds its nights).
    static func relink(from oldId: UUID, to newId: UUID, context: ModelContext) {
        guard oldId != newId else { return }
        for att in fetchAll(context) where att.linkedItemId == oldId {
            att.linkedItemId = newId
        }
    }

    /// Every id inside `trip` that an attachment can be linked to.
    static func ownerIds(in trip: Trip) -> Set<UUID> {
        var ids = Set<UUID>()
        for day in trip.days {
            day.transports.forEach { ids.insert($0.id) }
            day.destinations.forEach { ids.insert($0.id) }
            if let acc = day.accommodation { ids.insert(acc.id) }
        }
        trip.infoItems.forEach { ids.insert($0.id) }
        return ids
    }

    static func deleteFile(for att: Attachment) {
        try? FileManager.default.removeItem(at: localURL(for: att.localPath))
    }

    private static func fetchAll(_ context: ModelContext) -> [Attachment] {
        (try? context.fetch(FetchDescriptor<Attachment>())) ?? []
    }
}
