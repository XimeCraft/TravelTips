import Foundation

// MARK: - Plain-text itinerary for sharing
//
// Day by day: date, city, summary and timeline. Info items are deliberately
// left out because they often hold passport, insurance or booking numbers.

enum TripShareText {
    static func make(_ trip: Trip) -> String {
        var lines: [String] = []
        lines.append("\(trip.emoji) \(trip.name)")
        lines.append("\(fmtDate(trip.startDate)) – \(fmtDate(trip.endDate)) · " + String(localized: "\(trip.totalDays) days"))

        for (i, day) in trip.sortedDays.enumerated() {
            lines.append("")
            var header = String(localized: "Day \(i + 1) · \(fmtDate(day.date))")
            let city = day.city.trimmingCharacters(in: .whitespaces)
            if !city.isEmpty { header += " · \(city)" }
            lines.append(header)

            let summary = day.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            if !summary.isEmpty { lines.append(summary) }

            for item in day.sortedTimelineItems {
                let title = item.title.trimmingCharacters(in: .whitespaces)
                guard !title.isEmpty else { continue }
                let time = parseHHmm(item.time) != nil ? item.time + "  " : ""
                lines.append("  • \(time)\(title)")
                if let address = item.address?.trimmingCharacters(in: .whitespaces), !address.isEmpty {
                    lines.append("    📍 \(address)")
                }
            }
        }

        lines.append("")
        lines.append(String(localized: "Shared from TravelTips"))
        return lines.joined(separator: "\n")
    }
}
