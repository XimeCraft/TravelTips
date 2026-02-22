import SwiftUI
import SwiftData

@main
struct TravelTipsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Trip.self,
            TripDay.self,
            TransportInfo.self,
            Accommodation.self,
            Destination.self,
            DayDetail.self,
            InfoItem.self,
        ])
    }
}
