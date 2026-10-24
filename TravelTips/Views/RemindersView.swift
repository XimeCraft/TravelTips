import SwiftUI
import SwiftData

struct RemindersView: View {
    let trips: [Trip]

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]

    @State private var showInlineAdd = false
    @State private var newTaskText = ""

    var body: some View {
        ZStack(alignment: .topTrailing) {
            List {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("Todo")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("Stay on top of your trip")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 6)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Theme.bg)
                .listRowSeparator(.hidden)

                // MARK: Trip Reminders (auto, read-only)

                SectionHeader(title: "Trip Reminders")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.bg)
                    .listRowSeparator(.hidden)

                ForEach(tripReminders) { reminder in
                    TripReminderCard(reminder: reminder)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Theme.bg)
                        .listRowSeparator(.hidden)
                }

                if tripReminders.isEmpty {
                    Text("No upcoming trips")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textTer)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Theme.bg)
                        .listRowSeparator(.hidden)
                }

                // MARK: My Tasks (manual)

                SectionHeader(title: "My Tasks")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.bg)
                    .listRowSeparator(.hidden)

                if showInlineAdd {
                    HStack(spacing: 10) {
                        TextField("New task...", text: $newTaskText)
                            .font(.system(size: 14))
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onSubmit { addTask() }
                        Button("Cancel") {
                            showInlineAdd = false
                            newTaskText = ""
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.bg)
                    .listRowSeparator(.hidden)
                }

                if tasks.isEmpty && !showInlineAdd {
                    Text("No tasks yet — tap + to add one")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textTer)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Theme.bg)
                        .listRowSeparator(.hidden)
                }

                ForEach(tasks) { task in
                    TaskCard(task: task)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(task)
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

            AddButton {
                showInlineAdd = true
            }
            .padding(.top, 14)
            .padding(.trailing, 20)
        }
    }

    private var tripReminders: [TripReminderItem] {
        trips.compactMap { trip in
            let toStart = trip.daysLeft
            let toEnd = daysUntil(trip.endDate)
            guard toEnd >= 0 else { return nil }          // ended trips are not reminders

            let title: String
            if toStart > 1 {
                title = String(localized: "\(trip.name) starts in \(toStart) days")
            } else if toStart == 1 {
                title = String(localized: "\(trip.name) starts tomorrow")
            } else {
                title = String(localized: "\(trip.name) is happening now")
            }
            return TripReminderItem(
                icon: trip.emoji,
                title: title,
                subtitle: "\(fmtDate(trip.startDate)) – \(fmtDate(trip.endDate))"
            )
        }
    }

    private func addTask() {
        let text = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { showInlineAdd = false; return }
        let task = TaskItem(title: text)
        modelContext.insert(task)
        newTaskText = ""
        showInlineAdd = false
    }
}

// MARK: - Data

struct TripReminderItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

// MARK: - Trip Reminder Card (read-only)

private struct TripReminderCard: View {
    let reminder: TripReminderItem

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

// MARK: - Task Card (tap-to-edit, checkbox, swipe-to-delete)

private struct TaskCard: View {
    let task: TaskItem

    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        CardView {
            HStack(spacing: 12) {
                CheckboxView(isChecked: task.isDone, color: Theme.primary) {
                    task.isDone.toggle()
                    if task.isDone { isEditing = false }
                }

                if isEditing {
                    TextField("Task", text: Binding(
                        get: { task.title },
                        set: { task.title = $0 }
                    ))
                    .font(.system(size: 14, weight: .semibold))
                    .focused($isFocused)
                    .onSubmit { isEditing = false }
                } else {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .strikethrough(task.isDone)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !task.isDone else { return }
                            isEditing = true
                            isFocused = true
                        }
                }
            }
        }
        .opacity(task.isDone ? 0.45 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: task.isDone)
        .onChange(of: isFocused) { _, newValue in
            if !newValue { isEditing = false }
        }
    }
}
