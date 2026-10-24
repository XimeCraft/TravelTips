import SwiftUI
import SwiftData

// MARK: - Trip form (create + edit)

/// Preset trip colors. The first one is the app's primary green.
let tripColorPresets = ["076C44", "2196F3", "9C27B0", "E65100", "C62828", "00838F", "5D4037", "37474F"]

extension Trip {
    var color: Color { Color(hex: colorHex) }
}

struct TripFormSheet: View {
    /// nil = create a new trip.
    let editing: Trip?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var emoji: String
    @State private var colorHex: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var pendingRemoval: [TripDay] = []
    @State private var showRemovalConfirm = false
    @State private var pendingShift: Int? = nil

    private let quickEmojis = ["🇨🇳","🇳🇿","🇸🇬","🇯🇵","🇰🇷","🇺🇸","🇬🇧","🇫🇷","🇩🇪","🇮🇹",
                               "🇪🇸","🇹🇭","🇦🇪","🇪🇬","🇲🇦","🇹🇷","🇬🇷","🇵🇹","🇦🇺","✈️","🏖️","🏔️","🗺️","🧳"]

    init(editing: Trip? = nil) {
        self.editing = editing
        _name      = State(initialValue: editing?.name ?? "")
        _emoji     = State(initialValue: editing?.emoji ?? "")
        _colorHex  = State(initialValue: editing?.colorHex ?? tripColorPresets[0])
        _startDate = State(initialValue: editing?.startDate ?? Date())
        _endDate   = State(initialValue: editing?.endDate ?? Date().addingTimeInterval(86400 * 7))
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    SheetField(label: "Trip Name", text: $name, placeholder: "e.g. Egypt")
                    emojiField
                    colorField
                    dateFields

                    SheetSaveButton(label: editing == nil ? "Create Trip" : "Save") { save() }
                        .disabled(trimmedName.isEmpty)
                        .opacity(trimmedName.isEmpty ? 0.5 : 1)
                }
                .padding(20)
            }
            .confirmationDialog(
                Text("Remove \(pendingRemoval.count) days from the trip?"),
                isPresented: $showRemovalConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove Days", role: .destructive) { commitEdit() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(removalMessage)
            }
            .confirmationDialog(
                shiftTitle,
                isPresented: Binding(get: { pendingShift != nil }, set: { if !$0 { pendingShift = nil } }),
                titleVisibility: .visible
            ) {
                Button("Move Everything") {
                    if let days = pendingShift, let editing { TripDates.shift(editing, byDays: days) }
                    pendingShift = nil
                    commitEdit()
                }
                Button("Only Change the Dates", role: .destructive) {
                    pendingShift = nil
                    resizeOrConfirm()
                }
                Button("Cancel", role: .cancel) { pendingShift = nil }
            } message: {
                Text("Move keeps every day's plans, hotels and transport and shifts them with the trip. Only changing the dates removes the days that fall outside the new range.")
            }
            .onChange(of: startDate) { _, newStart in
                if endDate < newStart { endDate = newStart }
            }
            .navigationTitle(editing == nil ? Text("New Trip") : Text("Edit Trip"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }

    // MARK: Fields

    private func label(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Theme.textSec)
            .textCase(.uppercase)
            .kerning(0.8)
    }

    private var emojiField: some View {
        VStack(alignment: .leading, spacing: 5) {
            label("Emoji")
            TextField("🌍", text: $emoji)
                .font(.system(size: 22))
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickEmojis, id: \.self) { flag in
                        Button { emoji = flag } label: {
                            Text(flag)
                                .font(.system(size: 24))
                                .padding(6)
                                .background(emoji == flag ? Theme.primaryMuted : Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.bottom, 4)
    }

    private var colorField: some View {
        VStack(alignment: .leading, spacing: 5) {
            label("Color")
            HStack(spacing: 10) {
                ForEach(tripColorPresets, id: \.self) { hex in
                    Button { colorHex = hex } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 2).padding(3)
                                    .opacity(colorHex == hex ? 1 : 0)
                            )
                            .overlay(
                                Circle().stroke(Color(hex: hex), lineWidth: 2).padding(-3)
                                    .opacity(colorHex == hex ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Color \(hex)")
                    .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var dateFields: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                label("Start Date")
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Theme.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 5) {
                label("End Date")
                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Theme.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
        }
    }

    // MARK: Save

    private func save() {
        guard !trimmedName.isEmpty else { return }
        let finalEmoji = emoji.trimmingCharacters(in: .whitespaces).isEmpty ? "✈️" : emoji

        if let editing {
            if let offset = TripDates.shiftOffset(for: editing, start: startDate, end: endDate) {
                pendingShift = offset
            } else {
                resizeOrConfirm()
            }
            return
        }

        let cal = Calendar.current
        let trip = Trip(name: trimmedName, emoji: finalEmoji,
                        startDate: cal.startOfDay(for: startDate), endDate: cal.startOfDay(for: endDate),
                        colorHex: colorHex)
        for (i, date) in TripDates.dayStarts(from: startDate, to: endDate).enumerated() {
            trip.days.append(TripDay(date: date, city: "", summary: "", sortOrder: i))
        }
        modelContext.insert(trip)
        dismiss()
    }

    /// Resize path: confirm first if days with content would be removed.
    private func resizeOrConfirm() {
        guard let editing else { return }
        let removing = TripDates.daysToRemove(from: editing, start: startDate, end: endDate)
        if removing.contains(where: \.hasContent) {
            pendingRemoval = removing
            showRemovalConfirm = true
        } else {
            commitEdit()
        }
    }

    private var shiftTitle: Text {
        let days = pendingShift ?? 0
        return days > 0 ? Text("Move the trip \(days) days later?") : Text("Move the trip \(-days) days earlier?")
    }

    private func commitEdit() {
        guard let editing else { return }
        editing.name = trimmedName
        editing.emoji = emoji.trimmingCharacters(in: .whitespaces).isEmpty ? "✈️" : emoji
        editing.colorHex = colorHex
        let cal = Calendar.current
        if !cal.isDate(editing.startDate, inSameDayAs: startDate) || !cal.isDate(editing.endDate, inSameDayAs: endDate) {
            TripDates.apply(to: editing, start: startDate, end: endDate, context: modelContext)
        }
        dismiss()
    }

    private var removalMessage: String {
        let withContent = pendingRemoval.filter(\.hasContent)
        let lines = withContent.prefix(5).map { String(localized: "\(fmtDate($0.date)): \($0.contentSummary)") }
        var text = lines.joined(separator: "\n")
        if withContent.count > 5 { text += "\n" + String(localized: "…and \(withContent.count - 5) more") }
        return text + "\n\n" + String(localized: "Everything on these days, including attachments, will be deleted.")
    }
}
