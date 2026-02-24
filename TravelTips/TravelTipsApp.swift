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
        ])
        let config = ModelConfiguration(schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Dev convenience: wipe incompatible store on schema changes
            let storeDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let filenames = ["default.store", "default.store-shm", "default.store-wal"]
            for name in filenames {
                try? FileManager.default.removeItem(at: storeDir.appending(path: name))
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
