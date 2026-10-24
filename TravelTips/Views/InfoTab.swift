import SwiftUI
import SwiftData

struct InfoTab: View {
    let trip: Trip

    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    @State private var selectedInfo: InfoItem? = nil
    @State private var selectedEdit: InfoItem? = nil

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
                    InfoItemRow(item: item, onTap: { selectedEdit = item }) {
                        selectedInfo = item
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            if let idx = trip.infoItems.firstIndex(where: { $0.id == item.id }) {
                                let it = trip.infoItems[idx]
                                AttachmentStore.deleteAll(linkedTo: [it.id], context: modelContext)
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
        .sheet(item: $selectedInfo) { item in
            InfoDetailView(item: item)
        }
        .sheet(item: $selectedEdit) { item in
            AddInfoItemSheet(trip: trip, editing: item)
                .presentationDetents([.medium])
        }
    }
}

private struct InfoItemRow: View {
    let item: InfoItem
    let onTap: () -> Void
    let onViewDetail: () -> Void

    var body: some View {
        CardView(action: onTap) {
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

                ViewDetailsButton(color: Theme.primary, action: onViewDetail)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Add / Edit Info Item Sheet

private struct AddInfoItemSheet: View {
    let trip: Trip
    private let editing: InfoItem?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String
    @State private var details: String

    init(trip: Trip, editing: InfoItem? = nil) {
        self.trip    = trip
        self.editing = editing
        _title   = State(initialValue: editing?.title ?? "")
        _details = State(initialValue: editing?.details ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    SheetField(label: "Title", text: $title, placeholder: "e.g. Travel Insurance")
                    SheetField(label: "Details", text: $details, placeholder: "Important details...", multiline: true)

                    SheetSaveButton(label: "Save") {
                        guard !title.isEmpty else { return }
                        if let editing {
                            editing.title   = title
                            editing.details = details
                        } else {
                            let item = InfoItem(
                                title: title,
                                details: details,
                                sortOrder: trip.infoItems.count
                            )
                            modelContext.insert(item)
                            trip.infoItems.append(item)
                        }
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle(editing != nil ? Text("Edit Info") : Text("Add Info Item"))
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
