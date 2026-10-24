import SwiftUI
import SwiftData

@main
struct TravelTipsApp: App {
    let container: ModelContainer = StoreSetup.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
