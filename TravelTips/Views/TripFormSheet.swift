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
                    if editing == nil { dateFields }

                    SheetSaveButton(label: editing == nil ? "Create Trip" : "Save") { save() }
                        .disabled(trimmedName.isEmpty)
                        .opacity(trimmedName.isEmpty ? 0.5 : 1)
                }
                .padding(20)
            }
            .navigationTitle(editing == nil ? "New Trip" : "Edit Trip")
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

    private func label(_ text: String) -> some View {
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
            editing.name = trimmedName
            editing.emoji = finalEmoji
            editing.colorHex = colorHex
            dismiss()
            return
        }

        let trip = Trip(name: trimmedName, emoji: finalEmoji,
                        startDate: startDate, endDate: endDate, colorHex: colorHex)
        let calendar = Calendar.current
        var current = startDate
        var sortOrder = 0
        while current <= endDate {
            trip.days.append(TripDay(date: current, city: "", summary: "", sortOrder: sortOrder))
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? endDate.addingTimeInterval(86400)
            sortOrder += 1
        }
        modelContext.insert(trip)
        dismiss()
    }
}
