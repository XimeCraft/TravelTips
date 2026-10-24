import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Trip export (PDF / Markdown)
//
// One document model, two renderers. Info items are deliberately left out:
// they often hold passport, insurance or booking numbers.

struct TripDocument: Equatable {
    struct Table: Equatable {
        var headers: [String]
        var rows: [[String]]
    }

    struct TimelineLine: Equatable {
        var time: String?
        var text: String
        var address: String?
        var done: Bool
    }

    struct PlaceLine: Equatable {
        var name: String
        var details: [String]      // type, time, ticket
        var address: String?
        var notes: String?
    }

    struct Day: Equatable {
        var number: Int
        var heading: String        // "Day 1 · Tue, Oct 20"
        var city: String?
        var summary: String?
        var timeline: [TimelineLine]
        var places: [PlaceLine]
    }

    var title: String
    var subtitle: String
    var colorHex: String
    var glance: Table
    var transport: Table?
    var hotels: Table?
    var days: [Day]
}

enum TripExport {

    // MARK: Model

    static func document(for trip: Trip) -> TripDocument {
        let days = trip.sortedDays
        let dash = "—"

        let glance = TripDocument.Table(
            headers: [String(localized: "export.column.day", defaultValue: "Day", comment: "Itinerary table column: D1, D2, ..."),
                      String(localized: "Date"), String(localized: "City"), String(localized: "Plan")],
            rows: days.enumerated().map { i, day in
                [String(localized: "D\(i + 1)"), fmtDate(day.date), clean(day.city) ?? dash, clean(day.summary) ?? dash]
            }
        )

        var transportRows: [[String]] = []
        for day in days {
            for t in day.transports {
                transportRows.append([
                    fmtDate(day.date),
                    "\(t.type.emoji) \(t.type.displayName)",
                    "\(clean(t.from) ?? dash) → \(clean(t.to) ?? dash)",
                    clean(t.departureTime) ?? dash,
                    clean(t.arrivalTime) ?? dash,
                    clean(t.detail) ?? dash,
                ])
            }
        }
        let transport = transportRows.isEmpty ? nil : TripDocument.Table(
            headers: [String(localized: "Date"), String(localized: "Type"), String(localized: "Route"),
                      String(localized: "Departure"), String(localized: "Arrival"), String(localized: "Reference")],
            rows: transportRows)

        let stays = hotelStays(days)
        let hotels = stays.isEmpty ? nil : TripDocument.Table(
            headers: [String(localized: "Hotel"), String(localized: "Check-in"), String(localized: "Check-out"),
                      String(localized: "Nights"), String(localized: "Address")],
            rows: stays.map { s in
                [clean(s.name) ?? dash, fmtDate(s.checkIn), fmtDate(s.checkOut), "\(s.nights)", clean(s.address) ?? dash]
            })

        let dayBlocks = days.enumerated().map { i, day -> TripDocument.Day in
            TripDocument.Day(
                number: i + 1,
                heading: String(localized: "Day \(i + 1) · \(fmtDate(day.date))"),
                city: clean(day.city),
                summary: clean(day.summary),
                timeline: day.sortedTimelineItems.compactMap { item in
                    guard let text = clean(item.title) else { return nil }
                    return TripDocument.TimelineLine(
                        time: parseHHmm(item.time) != nil ? item.time : nil,
                        text: text,
                        address: clean(item.address),
                        done: item.isDone)
                },
                places: day.sortedDestinations.map { d in
                    var details = ["\(d.type.emoji) \(d.type.displayName)"]
                    if let time = clean(d.time) {
                        details.append(time == TimeRangeField.allDay ? String(localized: "All Day") : time)
                    }
                    if let price = clean(d.ticketPrice) { details.append(String(localized: "Ticket \(price)")) }
                    return TripDocument.PlaceLine(name: d.name, details: details,
                                                  address: clean(d.address), notes: clean(d.notes))
                })
        }

        return TripDocument(
            title: "\(trip.emoji) \(trip.name)",
            subtitle: "\(fmtDate(trip.startDate)) – \(fmtDate(trip.endDate)) · " + String(localized: "\(trip.totalDays) days"),
            colorHex: trip.colorHex,
            glance: glance, transport: transport, hotels: hotels, days: dayBlocks)
    }

    private struct Stay { var name: String; var address: String; var checkIn: Date; var checkOut: Date; var nights: Int }

    /// Consecutive nights at the same hotel; check-out is the morning after the last night.
    private static func hotelStays(_ days: [TripDay]) -> [Stay] {
        var stays: [Stay] = []
        var previous: String? = nil
        for day in days {
            guard let acc = day.accommodation else { previous = nil; continue }
            let checkOut = Calendar.current.date(byAdding: .day, value: 1, to: day.date) ?? day.date
            if acc.name == previous, !stays.isEmpty {
                stays[stays.count - 1].checkOut = checkOut
                stays[stays.count - 1].nights += 1
            } else {
                stays.append(Stay(name: acc.name, address: acc.address, checkIn: day.date, checkOut: checkOut, nights: 1))
            }
            previous = acc.name
        }
        return stays
    }

    private static func clean(_ s: String?) -> String? {
        guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty, t != noTimeSentinel else { return nil }
        return t
    }

    // MARK: Markdown

    static func markdown(_ doc: TripDocument) -> String {
        var md: [String] = []
        md.append("# \(doc.title)")
        md.append("")
        md.append("*\(doc.subtitle)*")

        func table(_ t: TripDocument.Table) {
            md.append("")
            md.append("| " + t.headers.map(mdCell).joined(separator: " | ") + " |")
            md.append("|" + t.headers.map { _ in " --- " }.joined(separator: "|") + "|")
            for row in t.rows { md.append("| " + row.map(mdCell).joined(separator: " | ") + " |") }
        }

        md.append("")
        md.append("## " + String(localized: "Itinerary at a Glance"))
        table(doc.glance)
        if let t = doc.transport {
            md.append("")
            md.append("## " + String(localized: "Transport"))
            table(t)
        }
        if let t = doc.hotels {
            md.append("")
            md.append("## " + String(localized: "Hotels"))
            table(t)
        }

        md.append("")
        md.append("## " + String(localized: "Day by Day"))
        for day in doc.days {
            md.append("")
            md.append("### " + day.heading + (day.city.map { " · \($0)" } ?? ""))
            if let s = day.summary {
                md.append("")
                md.append("> " + s.replacingOccurrences(of: "\n", with: "\n> "))
            }
            if !day.timeline.isEmpty {
                md.append("")
                for line in day.timeline {
                    let box = line.done ? "[x] " : ""
                    let time = line.time.map { "**\($0)** " } ?? ""
                    md.append("- \(box)\(time)\(line.text)")
                    if let a = line.address { md.append("  - 📍 \(a)") }
                }
            }
            if !day.places.isEmpty {
                md.append("")
                md.append("**" + String(localized: "Places") + "**")
                md.append("")
                for p in day.places {
                    md.append("- **\(p.name)** · " + p.details.joined(separator: " · "))
                    if let a = p.address { md.append("  - 📍 \(a)") }
                    if let n = p.notes { md.append("  - 💡 " + n.replacingOccurrences(of: "\n", with: " ")) }
                }
            }
        }
        md.append("")
        md.append("---")
        md.append("*" + String(localized: "Shared from TravelTips") + "*")
        return md.joined(separator: "\n") + "\n"
    }

    private static func mdCell(_ s: String) -> String {
        s.replacingOccurrences(of: "|", with: "\\|").replacingOccurrences(of: "\n", with: "<br>")
    }

    // MARK: HTML (for PDF)

    static func html(_ doc: TripDocument) -> String {
        let accent = "#" + doc.colorHex
        let onAccent = HexColor.luminance(doc.colorHex) > 0.45 ? "#1A1A1A" : "#FFFFFF"
        let tint = HexColor.luminance(doc.colorHex) > 0.5 ? "#6B5B2E" : accent
        let (r, g, b) = HexColor.rgb(doc.colorHex)
        let soft = "rgba(\(Int(r * 255)),\(Int(g * 255)),\(Int(b * 255)),0.10)"

        func table(_ t: TripDocument.Table, cls: String) -> String {
            var h = "<table class=\"\(cls)\"><thead><tr>"
            h += t.headers.map { "<th>\(esc($0))</th>" }.joined()
            h += "</tr></thead><tbody>"
            for row in t.rows { h += "<tr>" + row.map { "<td>\(esc($0))</td>" }.joined() + "</tr>" }
            return h + "</tbody></table>"
        }

        var body = """
        <div class="cover">
          <h1>\(esc(doc.title))</h1>
          <div class="sub">\(esc(doc.subtitle))</div>
        </div>
        <h2>\(esc(String(localized: "Itinerary at a Glance")))</h2>
        \(table(doc.glance, cls: "glance"))
        """
        if let t = doc.transport {
            let cls = doc.glance.rows.count > 8 ? " class=\"break\"" : ""
            body += "<h2\(cls)>\(esc(String(localized: "Transport")))</h2>" + table(t, cls: "transport")
        }
        if let t = doc.hotels {
            body += "<h2>\(esc(String(localized: "Hotels")))</h2>" + table(t, cls: "hotels")
        }
        body += "<h2 class=\"break\">\(esc(String(localized: "Day by Day")))</h2>"
        for day in doc.days {
            body += "<div class=\"day\"><div class=\"dayhead\"><span class=\"num\">D\(day.number)</span>"
            body += "<span class=\"dtitle\">\(esc(day.heading))</span>"
            if let c = day.city { body += "<span class=\"city\">\(esc(c))</span>" }
            body += "</div>"
            if let s = day.summary { body += "<p class=\"summary\">\(esc(s))</p>" }
            if !day.timeline.isEmpty {
                body += "<ul class=\"timeline\">"
                for line in day.timeline {
                    let time = line.time.map { "<span class=\"time\">\(esc($0))</span>" } ?? "<span class=\"time untimed\">•</span>"
                    body += "<li class=\"\(line.done ? "done" : "")\">\(time)"
                    body += "<span class=\"what\">\(esc(line.text))"
                    if let a = line.address { body += "<span class=\"addr\">📍 \(esc(a))</span>" }
                    body += "</span></li>"
                }
                body += "</ul>"
            }
            if !day.places.isEmpty {
                body += "<div class=\"places\"><div class=\"label\">\(esc(String(localized: "Places")))</div><ul>"
                for p in day.places {
                    body += "<li><b>\(esc(p.name))</b> <span class=\"meta\">\(esc(p.details.joined(separator: " · ")))</span>"
                    if let a = p.address { body += "<div class=\"addr\">📍 \(esc(a))</div>" }
                    if let n = p.notes { body += "<div class=\"note\">💡 \(esc(n))</div>" }
                    body += "</li>"
                }
                body += "</ul></div>"
            }
            body += "</div>"
        }
        body += "<div class=\"footer-note\">\(esc(String(localized: "Shared from TravelTips")))</div>"

        return """
        <!DOCTYPE html><html><head><meta charset="utf-8"><style>
        * { -webkit-print-color-adjust: exact; box-sizing: border-box; }
        body { font-family: -apple-system, "PingFang SC", "Helvetica Neue", sans-serif; color: #1A1A1A; font-size: 10.5pt; line-height: 1.45; margin: 0; }
        .cover { background: \(accent); color: \(onAccent); border-radius: 10px; padding: 18px 20px; margin-bottom: 14px; }
        .cover h1 { font-size: 24pt; margin: 0 0 4px 0; font-weight: 800; }
        .cover .sub { font-size: 11pt; opacity: 0.9; }
        h2 { font-size: 13pt; color: \(tint); border-bottom: 2px solid \(accent); padding-bottom: 3px; margin: 18px 0 8px 0; }
        h2.break { page-break-before: always; }
        table { width: 100%; border-collapse: collapse; font-size: 9.5pt; page-break-inside: auto; }
        tr { page-break-inside: avoid; }
        th { background: \(accent); color: \(onAccent); text-align: left; padding: 5px 7px; font-weight: 600; white-space: nowrap; }
        td { padding: 5px 7px; border-bottom: 1px solid #E6E6E6; vertical-align: top; }
        tbody tr:nth-child(even) td { background: \(soft); }
        table.glance td:first-child, table.glance th:first-child { width: 34px; font-weight: 700; color: \(tint); }
        table.glance td:nth-child(2) { white-space: nowrap; }
        table.transport td:nth-child(1), table.hotels td:nth-child(2), table.hotels td:nth-child(3) { white-space: nowrap; }
        table.transport td:nth-child(2) { white-space: nowrap; }
        table.transport td:nth-child(4), table.transport td:nth-child(5) { white-space: nowrap; font-variant-numeric: tabular-nums; }
        table.hotels td:nth-child(4) { text-align: center; }
        .day { page-break-inside: avoid; margin: 0 0 14px 0; border-left: 4px solid \(accent); padding: 2px 0 2px 12px; }
        .dayhead { display: flex; align-items: baseline; gap: 8px; margin-bottom: 4px; }
        .num { background: \(accent); color: \(onAccent); font-weight: 800; border-radius: 5px; padding: 1px 6px; font-size: 9.5pt; }
        .dtitle { font-weight: 700; font-size: 11.5pt; }
        .city { color: #666; font-size: 10pt; margin-left: auto; }
        .summary { margin: 2px 0 6px 0; color: #333; font-style: italic; }
        ul { margin: 0; padding: 0; list-style: none; }
        .timeline li { display: flex; gap: 10px; padding: 2px 0; }
        .timeline .time { width: 70px; flex-shrink: 0; font-weight: 700; color: \(tint); font-variant-numeric: tabular-nums; }
        .timeline .untimed { color: #C8C8C8; font-weight: 400; }
        .timeline .what { flex: 1; }
        .timeline li.done .what { color: #999; text-decoration: line-through; }
        .addr { display: block; color: #777; font-size: 9pt; }
        .places { margin-top: 6px; background: \(soft); border-radius: 6px; padding: 6px 10px; }
        .places .label { font-weight: 700; font-size: 9pt; color: \(tint); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 2px; }
        .places li { padding: 2px 0; }
        .places .meta { color: #666; font-size: 9pt; }
        .note { color: #555; font-size: 9pt; }
        .footer-note { margin-top: 18px; color: #AAA; font-size: 8.5pt; text-align: center; }
        </style></head><body>\(body)</body></html>
        """
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "\n", with: "<br>")
    }

    // MARK: PDF

    /// A4 PDF rendered from `html`, with "footer · page/total" at the bottom of each page.
    @MainActor
    static func pdf(html: String, footer: String) -> Data {
        let paper = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = FooterPageRenderer(footer: footer)
        renderer.addPrintFormatter(UIMarkupTextPrintFormatter(markupText: html), startingAtPageAt: 0)
        renderer.setValue(paper, forKey: "paperRect")
        renderer.setValue(paper.insetBy(dx: 36, dy: 36), forKey: "printableRect")

        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, paper, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: renderer.numberOfPages))
        for page in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: page, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        return data as Data
    }

    private final class FooterPageRenderer: UIPrintPageRenderer {
        let footer: String
        init(footer: String) {
            self.footer = footer
            super.init()
            footerHeight = 20
        }

        override func drawFooterForPage(at pageIndex: Int, in footerRect: CGRect) {
            let text = "\(footer)   \(pageIndex + 1)/\(numberOfPages)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.gray,
            ]
            let size = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: footerRect.midX - size.width / 2, y: footerRect.maxY - size.height - 4),
                      withAttributes: attrs)
        }
    }

    static func fileName(for trip: Trip, ext: String) -> String {
        let base = trip.name.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined()
            .trimmingCharacters(in: .whitespaces)
        return (base.isEmpty ? "Trip" : base) + "." + ext
    }
}

// MARK: - Share sheet items (rendered only when the user picks a destination)

struct TripPDFFile: Transferable {
    let html: String
    let footer: String
    let fileName: String

    init(trip: Trip) {
        html = TripExport.html(TripExport.document(for: trip))
        footer = "\(trip.emoji) \(trip.name)"
        fileName = TripExport.fileName(for: trip, ext: "pdf")
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { item in
            let data = await TripExport.pdf(html: item.html, footer: item.footer)
            let url = FileManager.default.temporaryDirectory.appending(path: item.fileName)
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

struct TripMarkdownFile: Transferable {
    let markdown: String
    let fileName: String

    init(trip: Trip) {
        markdown = TripExport.markdown(TripExport.document(for: trip))
        fileName = TripExport.fileName(for: trip, ext: "md")
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: UTType(filenameExtension: "md", conformingTo: .plainText) ?? .plainText) { item in
            let url = FileManager.default.temporaryDirectory.appending(path: item.fileName)
            try item.markdown.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}
