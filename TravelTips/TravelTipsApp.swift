import SwiftUI
import SwiftData

@main
struct TravelTipsApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Trip.self,
            TripDay.self,
            TransportInfo.self,
            Accommodation.self,
            Destination.self,
            TimelineItem.self,
            InfoItem.self,
            TaskItem.self,
            Attachment.self,
            PackingItem.self,
            PackingTag.self,
        ])
        let config = ModelConfiguration(schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Schema mismatch fallback. NEVER delete the store — that destroys user data.
            // Move it aside to a timestamped backup so it can always be recovered, then recreate.
            let fm = FileManager.default
            let storeDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let backupDir = storeDir.appending(path: "StoreBackups/\(Int(Date().timeIntervalSince1970))")
            try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
            for name in ["default.store", "default.store-shm", "default.store-wal"] {
                let src = storeDir.appending(path: name)
                if fm.fileExists(atPath: src.path) {
                    try? fm.moveItem(at: src, to: backupDir.appending(path: name))
                }
            }
            container = try! ModelContainer(for: schema, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
