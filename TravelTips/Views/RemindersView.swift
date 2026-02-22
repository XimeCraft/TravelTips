import SwiftUI

struct RemindersView: View {
    let trips: [Trip]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reminders")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("Upcoming tasks across all trips")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)

                SectionHeader(title: "Next 7 Days")

                // Dynamic reminder cards based on Egypt trip
                ForEach(reminders) { reminder in
                    ReminderCard(reminder: reminder)
                }

                Spacer(minLength: 20)
            }
        }
    }

    private var reminders: [ReminderItem] {
        var items: [ReminderItem] = []
        for trip in trips {
            let d = trip.daysLeft
            items.append(ReminderItem(
                icon: trip.emoji,
                title: "\(trip.name) trip \(d > 0 ? "starts in \(d) days" : "is now!")",
                subtitle: "Don't forget: visa photo, travel insurance"
            ))
        }
        items.append(contentsOf: [
            ReminderItem(icon: "💰", title: "Prepare USD cash for visa",
                         subtitle: "$25 exact change recommended"),
            ReminderItem(icon: "📱", title: "Download offline maps",
                         subtitle: "Cairo, Luxor, Marsa Alam areas"),
        ])
        return items
    }
}

// MARK: - Data

struct ReminderItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

private struct ReminderCard: View {
    let reminder: ReminderItem

    var body: some View {
        CardView {
            HStack(spacing: 12) {
                Text(reminder.icon)
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text(reminder.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSec)
                }
            }
        }
    }
}
