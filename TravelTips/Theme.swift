import SwiftUI

// MARK: - Theme Colors

enum Theme {
    static let primary      = Color(hex: "076C44")
    static let primaryLight = Color(hex: "0A8A58")
    static let primaryMuted = Color(hex: "076C44").opacity(0.19)
    static let primaryFaint = Color(hex: "076C44").opacity(0.07)
    static let primaryGhost = Color(hex: "076C44").opacity(0.03)
    static let accent       = Color(hex: "0B9B60")
    static let bg           = Color(hex: "F4F5F2")
    static let card         = Color.white
    static let textPrimary  = Color(hex: "1A1A1A")
    static let textSec      = Color(hex: "888888")
    static let textTer      = Color(hex: "AAAAAA")
    static let border       = Color.black.opacity(0.06)

    // Type system colors (MVP2)
    static let transport    = Color(hex: "2196F3")
    static let hotel        = Color(hex: "9C27B0")
    static let attraction   = Color(hex: "F9A825")
    static let activity     = Color(hex: "00BCD4")
    static let typeOther    = Color(hex: "9E9E9E")
}

// MARK: - TimelineType color extension

extension TimelineType {
    var color: Color {
        switch self {
        case .flight, .drive, .train, .bus, .ferry: return Theme.transport
        case .hotel:      return Theme.hotel
        case .attraction: return Theme.attraction
        case .restaurant: return Theme.primary
        case .activity:   return Theme.activity
        case .other:      return Theme.typeOther
        }
    }
}

extension DestinationType {
    var color: Color {
        switch self {
        case .attraction: return Theme.attraction
        case .activity:   return Theme.activity
        case .restaurant: return Theme.primary
        case .shopping:   return Theme.transport
        case .other:      return Theme.typeOther
        }
    }
}

// MARK: - Color(hex:) extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Date helpers

// Localized from templates: "Sat, Oct 24" in English, "10月24日 周六" in Chinese.
private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.setLocalizedDateFormatFromTemplate("EEEMMMd")
    return f
}()

private let shortDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.setLocalizedDateFormatFromTemplate("MMMd")
    return f
}()

func fmtDate(_ date: Date) -> String { dateFormatter.string(from: date) }

func fmtDateShort(_ date: Date) -> String { shortDateFormatter.string(from: date) }

func daysBetween(_ start: Date, _ end: Date) -> Int {
    let cal = Calendar.current
    return (cal.dateComponents([.day], from: start, to: end).day ?? 0) + 1
}

func daysUntil(_ date: Date) -> Int {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let target = cal.startOfDay(for: date)
    return cal.dateComponents([.day], from: today, to: target).day ?? 0
}
