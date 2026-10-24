import SwiftUI

// MARK: - Time string helpers
//
// Times stay stored as String (schema unchanged until group C). New writes are
// always "HH:mm", a range "HH:mm-HH:mm", "All Day", or "" for none. Older
// free-text values are preserved untouched until the user picks a new time.

/// Sentinel the timeline uses for "no time".
let noTimeSentinel = "--:--"

/// Minutes since midnight of the first time in `s`, or nil if there is none.
/// Accepts "8:05", "08:05", "08：05", "0805" and the start of a range "10:30-12:00".
func parseHHmm(_ s: String?) -> Int? {
    guard let s else { return nil }
    let trimmed = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "：", with: ":")
    guard let match = trimmed.firstMatch(of: /^(\d{1,2}):?(\d{2})/) else { return nil }
    guard let h = Int(match.1), let m = Int(match.2), (0..<24).contains(h), (0..<60).contains(m) else { return nil }
    return h * 60 + m
}

/// Minutes since midnight if `s` is exactly one time and nothing else
/// ("09:00" yes, "09:00 sharp" no). Used to decide whether a picker can show a
/// value without hiding part of it.
func exactHHmm(_ s: String) -> Int? {
    let t = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "：", with: ":")
    guard t.wholeMatch(of: /\d{1,2}:?\d{2}/) != nil else { return nil }
    return parseHHmm(t)
}

/// "HH:mm" for minutes since midnight.
func formatHHmm(_ minutes: Int) -> String {
    String(format: "%02d:%02d", minutes / 60, minutes % 60)
}

private func isEmptyTime(_ s: String) -> Bool {
    let t = s.trimmingCharacters(in: .whitespaces)
    return t.isEmpty || t == noTimeSentinel
}

/// Fixed reference day so DST transitions never shift a picked time.
private func dateFor(minutes: Int) -> Date {
    var c = DateComponents()
    c.year = 2001; c.month = 1; c.day = 1
    c.hour = minutes / 60; c.minute = minutes % 60
    return Calendar.current.date(from: c) ?? Date(timeIntervalSinceReferenceDate: 0)
}

private func minutesFor(date: Date) -> Int {
    let c = Calendar.current.dateComponents([.hour, .minute], from: date)
    return (c.hour ?? 0) * 60 + (c.minute ?? 0)
}

// MARK: - Shared pieces

private struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Theme.textSec)
            .textCase(.uppercase)
            .kerning(0.8)
    }
}

private struct ChipButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

private struct ClearButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Theme.textTer)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear time")
    }
}

/// A compact time picker bound to minutes since midnight.
private struct MinutePicker: View {
    let minutes: Int
    let onChange: (Int) -> Void
    var body: some View {
        DatePicker("", selection: Binding(
            get: { dateFor(minutes: minutes) },
            set: { onChange(minutesFor(date: $0)) }
        ), displayedComponents: .hourAndMinute)
        .labelsHidden()
        .datePickerStyle(.compact)
        .tint(Theme.primary)
    }
}

/// Shows an unparseable legacy value and lets the user replace it.
private struct LegacyValue: View {
    let text: String
    let onReplace: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            ChipButton(title: "Pick time", action: onReplace)
        }
    }
}

// MARK: - TimeField (single time)

/// Optional single time. Writes "HH:mm" or "" into `text`.
struct TimeField: View {
    let label: String
    @Binding var text: String
    var defaultMinutes: Int = 9 * 60

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            FieldLabel(text: label)
            HStack(spacing: 8) {
                if isEmptyTime(text) {
                    ChipButton(title: "+ Set time") { text = formatHHmm(defaultMinutes) }
                } else if let m = exactHHmm(text) {
                    MinutePicker(minutes: m) { text = formatHHmm($0) }
                    ClearButton { text = "" }
                } else {
                    LegacyValue(text: text) { text = formatHHmm(defaultMinutes) }
                }
            }
            .frame(minHeight: 38, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

// MARK: - TimeRangeField (start, optional end, or all day)

/// Optional time or time range for places. Writes "HH:mm", "HH:mm-HH:mm",
/// "All Day" or "" into `text`.
struct TimeRangeField: View {
    let label: String
    @Binding var text: String

    static let allDay = "All Day"

    /// Parsed value, or nil if `text` is anything other than "time" or "time-time".
    private var parts: (start: Int, end: Int?)? {
        let pieces = text.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        switch pieces.count {
        case 1:
            return exactHHmm(pieces[0]).map { ($0, nil) }
        case 2:
            guard let start = exactHHmm(pieces[0]), let end = exactHHmm(pieces[1]) else { return nil }
            return (start, end)
        default:
            return nil
        }
    }

    private func write(start: Int, end: Int?) {
        if let end { text = "\(formatHHmm(start))-\(formatHHmm(end))" }
        else { text = formatHHmm(start) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            FieldLabel(text: label)
            HStack(spacing: 8) {
                if isEmptyTime(text) {
                    ChipButton(title: "+ Set time") { write(start: 9 * 60, end: nil) }
                    ChipButton(title: Self.allDay) { text = Self.allDay }
                } else if text.caseInsensitiveCompare(Self.allDay) == .orderedSame {
                    Text(Self.allDay)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textPrimary)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    ClearButton { text = "" }
                } else if let p = parts {
                    MinutePicker(minutes: p.start) { newStart in
                        write(start: newStart, end: p.end.map { max($0, newStart) })
                    }
                    if let end = p.end {
                        Text("–").foregroundColor(Theme.textSec)
                        MinutePicker(minutes: end) { write(start: p.start, end: $0) }
                    } else {
                        ChipButton(title: "+ End") { write(start: p.start, end: min(p.start + 60, 23 * 60 + 59)) }
                    }
                    ClearButton { text = "" }
                } else {
                    LegacyValue(text: text) { write(start: 9 * 60, end: nil) }
                }
            }
            .frame(minHeight: 38, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}
