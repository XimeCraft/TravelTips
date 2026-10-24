import Foundation
import SwiftData

// MARK: - Opening the store
//
// Two safety nets around the schema migration:
// 1. Before the first launch that might migrate, the store is *copied* to
//    Application Support/StoreBackups/pre-v<N>/. Nothing is moved or deleted.
// 2. If the store still can't be opened, it is moved aside to a timestamped
//    backup, an empty store is created, and the backup path is recorded so the
//    UI can tell the user (see `recoveryNotice`). Data is never deleted.

enum StoreSetup {
    static let storeFiles = ["default.store", "default.store-shm", "default.store-wal"]
    static let recoveryNoticeKey = "storeRecoveryNotice"
    private static let preMigrationBackupKey = "preMigrationBackupVersion"

    static var supportDir: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema)

        backUpBeforeMigrationIfNeeded()

        do {
            return try ModelContainer(for: schema, migrationPlan: TravelTipsMigrationPlan.self,
                                      configurations: config)
        } catch {
            let backup = moveStoreAside()
            let location = backup?.path ?? String(localized: "an unknown location")
            UserDefaults.standard.set(
                String(localized: "Your trips couldn't be opened by this version, so a new empty database was created. The original was kept at \(location).")
                + "\n\n" + error.localizedDescription,
                forKey: recoveryNoticeKey)
            return try! ModelContainer(for: schema, migrationPlan: TravelTipsMigrationPlan.self,
                                       configurations: config)
        }
    }

    /// Copies the store once per schema version, before that version first opens it.
    private static func backUpBeforeMigrationIfNeeded() {
        let current = SchemaV2.versionIdentifier.major
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: preMigrationBackupKey) < current else { return }

        let fm = FileManager.default
        let store = supportDir.appending(path: "default.store")
        guard fm.fileExists(atPath: store.path) else {
            defaults.set(current, forKey: preMigrationBackupKey)   // fresh install, nothing to back up
            return
        }
        let dest = supportDir.appending(path: "StoreBackups/pre-v\(current)")
        do {
            try fm.createDirectory(at: dest, withIntermediateDirectories: true)
            for name in storeFiles {
                let src = supportDir.appending(path: name)
                let dst = dest.appending(path: name)
                guard fm.fileExists(atPath: src.path) else { continue }
                if fm.fileExists(atPath: dst.path) { try fm.removeItem(at: dst) }
                try fm.copyItem(at: src, to: dst)
            }
            defaults.set(current, forKey: preMigrationBackupKey)
        } catch {
            // Leave the flag unset so the next launch tries again; migration still proceeds.
        }
    }

    private static func moveStoreAside() -> URL? {
        let fm = FileManager.default
        let dir = supportDir.appending(path: "StoreBackups/failed-\(Int(Date().timeIntervalSince1970))")
        guard (try? fm.createDirectory(at: dir, withIntermediateDirectories: true)) != nil else { return nil }
        for name in storeFiles {
            let src = supportDir.appending(path: name)
            if fm.fileExists(atPath: src.path) {
                try? fm.moveItem(at: src, to: dir.appending(path: name))
            }
        }
        return dir
    }
}
