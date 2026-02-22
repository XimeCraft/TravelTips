import SwiftUI
import SwiftData

struct InfoTab: View {
    let trip: Trip

    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            List {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Essential Info")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("Things to prepare before departure")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Theme.bg)
                .listRowSeparator(.hidden)

                ForEach(trip.sortedInfoItems) { item in
                    InfoItemRow(item: item)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let idx = trip.infoItems.firstIndex(where: { $0.id == item.id }) {
                                    let it = trip.infoItems[idx]
                                    trip.infoItems.remove(at: idx)
                                    modelContext.delete(it)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Theme.bg)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            AddButton { showAddSheet = true }
                .padding(.top, 14)
                .padding(.trailing, 20)
        }
        .sheet(isPresented: $showAddSheet) {
            AddInfoItemSheet(trip: trip)
                .presentationDetents([.medium])
        }
    }
}

private struct InfoItemRow: View {
    let item: InfoItem

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(item.details)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSec)
                    .lineSpacing(4)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)

                ViewDetailsButton(color: Theme.primary)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Add Info Item Sheet

private struct AddInfoItemSheet: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var details = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    SheetField(label: "Title", text: $title, placeholder: "e.g. Travel Insurance")
                    SheetField(label: "Details", text: $details, placeholder: "Important details...", multiline: true)

                    SheetSaveButton(label: "Save") {
                        guard !title.isEmpty else { return }
                        let item = InfoItem(
                            title: title,
                            details: details,
                            sortOrder: trip.infoItems.count
                        )
                        modelContext.insert(item)
                        trip.infoItems.append(item)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Info Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }
}
