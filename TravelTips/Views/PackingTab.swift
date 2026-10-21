import SwiftUI
import SwiftData

// MARK: - Packing Tab (global, shared across trips)

struct PackingTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PackingItem.sortOrder) private var allItems: [PackingItem]
    @Query(sort: \PackingTag.sortOrder) private var tags: [PackingTag]

    @State private var showAddSheet = false
    @State private var showArchive = false
    @State private var selectedItem: PackingItem? = nil

    private var items: [PackingItem] { allItems.filter { !$0.isArchived } }
    private var archivedCount: Int { allItems.filter { $0.isArchived }.count }
    private var packedCount: Int { items.filter { $0.isPacked }.count }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            List {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Packing")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("Packed \(packedCount)/\(items.count)")
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

                ForEach(packingSections(items, tags: tags), id: \.tag) { section in
                    Section {
                        ForEach(section.items) { item in
                            PackingItemRow(item: item) { selectedItem = item }
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        item.isArchived = true
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    .tint(Theme.textSec)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Theme.bg)
                                .listRowSeparator(.hidden)
                        }
                    } header: {
                        PackingSectionHeader(
                            title: section.tag,
                            packed: section.items.filter { $0.isPacked }.count,
                            total: section.items.count
                        )
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            HStack(spacing: 12) {
                Button { showArchive = true } label: {
                    Image(systemName: "archivebox")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.primary)
                        .frame(width: 30, height: 30)
                        .background(Theme.primaryFaint)
                        .cornerRadius(9)
                        .overlay(alignment: .topTrailing) {
                            if archivedCount > 0 {
                                Text("\(archivedCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Theme.textSec)
                                    .clipShape(Capsule())
                                    .offset(x: 6, y: -5)
                            }
                        }
                }
                .buttonStyle(.plain)

                AddButton { showAddSheet = true }
            }
            .padding(.top, 14)
            .padding(.trailing, 20)
        }
        .sheet(isPresented: $showAddSheet) {
            AddPackingItemSheet(tags: tags, nextSortOrder: (allItems.map(\.sortOrder).max() ?? -1) + 1)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showArchive) {
            PackingArchiveView()
        }
        .sheet(item: $selectedItem) { item in
            PackingDetailView(item: item, tags: tags)
        }
    }
}

// MARK: - Archive View (same layout; left-swipe deletes, right-swipe restores)

struct PackingArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PackingItem.sortOrder) private var allItems: [PackingItem]
    @Query(sort: \PackingTag.sortOrder) private var tags: [PackingTag]

    @State private var selectedItem: PackingItem? = nil

    private var archived: [PackingItem] { allItems.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            Group {
                if archived.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 34))
                            .foregroundColor(Theme.textTer)
                        Text("No archived items")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSec)
                        Text("Swipe an item left in Packing to archive it.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textTer)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                    .background(Theme.bg)
                } else {
                    List {
                        ForEach(packingSections(archived, tags: tags), id: \.tag) { section in
                            Section {
                                ForEach(section.items) { item in
                                    PackingItemRow(item: item) { selectedItem = item }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                modelContext.delete(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                item.isArchived = false
                                            } label: {
                                                Label("Restore", systemImage: "arrow.uturn.left")
                                            }
                                            .tint(Theme.primary)
                                        }
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Theme.bg)
                                        .listRowSeparator(.hidden)
                                }
                            } header: {
                                PackingSectionHeader(
                                    title: section.tag,
                                    packed: section.items.filter { $0.isPacked }.count,
                                    total: section.items.count
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Theme.bg)
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(Theme.primary)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            PackingDetailView(item: item, tags: tags)
        }
    }
}

// MARK: - Group items by tag (in tag order), "Untagged" bucket last

private func packingSections(_ items: [PackingItem], tags: [PackingTag]) -> [(tag: String, items: [PackingItem])] {
    var result: [(String, [PackingItem])] = []
    for tag in tags {
        let group = items.filter { $0.tag == tag.name }
        if !group.isEmpty { result.append((tag.name, group)) }
    }
    let untagged = items.filter { item in
        item.tag == nil || !tags.contains(where: { $0.name == item.tag })
    }
    if !untagged.isEmpty { result.append(("Untagged", untagged)) }
    return result
}

// MARK: - Section Header

private struct PackingSectionHeader: View {
    let title: String
    let packed: Int
    let total: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .kerning(1)
            Spacer()
            Text("\(packed)/\(total)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textTer)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .textCase(nil)
    }
}

// MARK: - Item Row

private struct PackingItemRow: View {
    @Bindable var item: PackingItem
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CheckboxView(isChecked: item.isPacked, color: Theme.primary, size: 20) {
                item.isPacked.toggle()
            }

            Button(action: onTap) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(item.isPacked ? Theme.textTer : Theme.textPrimary)
                        .strikethrough(item.isPacked)

                    if item.quantity > 1 {
                        Text("×\(item.quantity)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.primaryFaint)
                            .cornerRadius(5)
                    }

                    Spacer()

                    if let notes = item.notes, !notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textTer)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTer)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.card)
        .cornerRadius(12)
        .opacity(item.isPacked ? 0.55 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: item.isPacked)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Detail / Edit View

struct PackingDetailView: View {
    @Bindable var item: PackingItem
    let tags: [PackingTag]

    @Environment(\.dismiss) private var dismiss

    private var notesBinding: Binding<String> {
        Binding(get: { item.notes ?? "" },
                set: { item.notes = $0.isEmpty ? nil : $0 })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    SheetField(label: "Name", text: $item.name, placeholder: "Item name")

                    VStack(alignment: .leading, spacing: 5) {
                        fieldLabel("Tag")
                        TagPicker(selection: $item.tag, tags: tags)
                    }
                    .padding(.bottom, 4)

                    QuantityStepperField(quantity: $item.quantity)

                    HStack(spacing: 12) {
                        CheckboxView(isChecked: item.isPacked, color: Theme.primary, size: 22) {
                            item.isPacked.toggle()
                        }
                        Text(item.isPacked ? "Packed ✓" : "Mark as packed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(item.isPacked ? Theme.primary : Theme.textSec)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.bottom, 4)

                    SheetField(label: "Notes", text: notesBinding,
                               placeholder: "e.g. which 8 t-shirts to bring…", multiline: true)
                }
                .padding(20)
            }
            .background(Theme.bg)
            .navigationTitle("Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(Theme.primary)
                }
            }
        }
    }
}

// MARK: - Add Sheet

private struct AddPackingItemSheet: View {
    let tags: [PackingTag]
    let nextSortOrder: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var tag: String? = nil
    @State private var quantity = 1
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    SheetField(label: "Name", text: $name, placeholder: "Item name")

                    VStack(alignment: .leading, spacing: 5) {
                        fieldLabel("Tag")
                        TagPicker(selection: $tag, tags: tags)
                    }
                    .padding(.bottom, 4)

                    QuantityStepperField(quantity: $quantity)

                    SheetField(label: "Notes", text: $notes,
                               placeholder: "Additional details…", multiline: true)

                    SheetSaveButton(label: "Save") {
                        guard !name.isEmpty else { return }
                        let item = PackingItem(
                            name: name,
                            tag: tag,
                            quantity: quantity,
                            notes: notes.isEmpty ? nil : notes,
                            sortOrder: nextSortOrder
                        )
                        modelContext.insert(item)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Item")
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

// MARK: - Tag Picker (select from set; add custom tags)

private struct TagPicker: View {
    @Binding var selection: String?
    let tags: [PackingTag]

    @Environment(\.modelContext) private var modelContext
    @State private var showNewTagAlert = false
    @State private var newTagName = ""

    var body: some View {
        Menu {
            Button("None") { selection = nil }
            ForEach(tags) { tag in
                Button(tag.name) { selection = tag.name }
            }
            Divider()
            Button {
                showNewTagAlert = true
            } label: {
                Label("New Tag…", systemImage: "plus")
            }
        } label: {
            HStack {
                Text(selection ?? "None")
                    .font(.system(size: 14))
                    .foregroundColor(selection == nil ? Theme.textTer : Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSec)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .tint(Theme.primary)
        .alert("New Tag", isPresented: $showNewTagAlert) {
            TextField("Tag name", text: $newTagName)
            Button("Add") { addTag() }
            Button("Cancel", role: .cancel) { newTagName = "" }
        }
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        newTagName = ""
        guard !name.isEmpty else { return }
        if !tags.contains(where: { $0.name == name }) {
            let order = (tags.map(\.sortOrder).max() ?? -1) + 1
            modelContext.insert(PackingTag(name: name, sortOrder: order))
        }
        selection = name
    }
}

// MARK: - Quantity Stepper Field

private struct QuantityStepperField: View {
    @Binding var quantity: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            fieldLabel("Quantity")
            HStack {
                Text("\(quantity)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Stepper("", value: $quantity, in: 1...99)
                    .labelsHidden()
                    .tint(Theme.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Shared label style

private func fieldLabel(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(Theme.textSec)
        .textCase(.uppercase)
        .kerning(0.8)
}
