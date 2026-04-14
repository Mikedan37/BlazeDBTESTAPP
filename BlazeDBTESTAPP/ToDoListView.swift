//
//  ContentView.swift
//  BlazeDBTESTAPP
//
//  Created by Michael Danylchuk on 4/9/26.
//
import SwiftUI
import BlazeDB

enum ToDoPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}

enum ToDoSortMode: String, CaseIterable, Identifiable {
    case priority = "Priority"
    case dueDate = "Due Date"
    case alphabetical = "Alphabetical"

    var id: String { rawValue }
}

struct ToDoItem: BlazeStorable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var priority: ToDoPriority = .medium
    var dueDate: Date? = nil
    var isDone: Bool = false
    var createdAt: Date?
    var updatedAt: Date?

    var touchedAt: Date {
        max(createdAt ?? .distantPast, updatedAt ?? .distantPast)
    }
}

struct ToDoListView: View {
    @Environment(\.blazeDBClient) private var db
    @BlazeStorableQuery(kind: ToDoItem.self) private var items: [ToDoItem]
    @BlazeStorableQuery(kind: AppSettings.self, where: "id", equals: .uuid(AppSettings.singletonID)) private var settingsRows: [AppSettings]

    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var sortMode: ToDoSortMode = .priority

    @State private var editingID: UUID?
    @State private var editingTitle = ""
    @State private var editingNotes = ""
    @State private var editingPriority: ToDoPriority = .medium
    @State private var editingHasDueDate = false
    @State private var editingDueDate = Date()

    private var settings: AppSettings {
        settingsRows.first ?? .default
    }

    private var cardSpacing: CGFloat {
        settings.compactMode ? 8 : 12
    }

    private var filteredItems: [ToDoItem] {
        let base: [ToDoItem]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            base = items
        } else {
            let query = searchText.lowercased()
            base = items.filter {
                $0.title.lowercased().contains(query) ||
                $0.notes.lowercased().contains(query)
            }
        }

        switch sortMode {
        case .priority:
            return base.sorted {
                let lhsRank = priorityRank($0.priority)
                let rhsRank = priorityRank($1.priority)
                if lhsRank != rhsRank { return lhsRank > rhsRank }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

        case .dueDate:
            return base.sorted {
                switch ($0.dueDate, $1.dueDate) {
                case let (lhs?, rhs?):
                    return lhs < rhs
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
            }

        case .alphabetical:
            return base.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
    }

    private var openItems: [ToDoItem] {
        filteredItems.filter { !$0.isDone }
    }

    private var completedInFilter: [ToDoItem] {
        filteredItems.filter { $0.isDone }
    }

    private var completedItems: [ToDoItem] {
        settings.showCompletedTasks ? completedInFilter : []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                controlsRow

                if filteredItems.isEmpty {
                    emptyState
                } else {
                    taskSection(title: "To Do", items: openItems)

                    if !completedItems.isEmpty {
                        taskSection(title: "Completed", items: completedItems, dimmed: true)
                    }
                }
            }
            .frame(maxWidth: 860, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .toolbar {
            Button("Add") {
                showingAddSheet = true
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddToDoItemView(initialPriority: settings.defaultTodoPriority)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("To-Do List")
                .font(.largeTitle.bold())

            HStack(spacing: 12) {
                statusPill(title: "\(openItems.count) Open", color: .blue)
                statusPill(title: "\(completedInFilter.count) Completed", color: .green)
            }
        }
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search tasks", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            Menu {
                Picker("Sort", selection: $sortMode) {
                    ForEach(ToDoSortMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.windowBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func taskSection(title: String, items: [ToDoItem], dimmed: Bool = false) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                VStack(spacing: cardSpacing) {
                    ForEach(items, id: \.id) { item in
                        ToDoCard(
                            item: item,
                            compact: settings.compactMode,
                            isEditing: editingID == item.id,
                            editingTitle: $editingTitle,
                            editingNotes: $editingNotes,
                            editingPriority: $editingPriority,
                            editingHasDueDate: $editingHasDueDate,
                            editingDueDate: $editingDueDate,
                            onBeginEdit: {
                                editingID = item.id
                                editingTitle = item.title
                                editingNotes = item.notes
                                editingPriority = item.priority
                                editingHasDueDate = item.dueDate != nil
                                editingDueDate = item.dueDate ?? Date()
                            },
                            onCommitEdit: {
                                commitEdit(for: item)
                            },
                            onCancelEdit: {
                                cancelEdit()
                            },
                            onToggle: { toggle(item) },
                            onDelete: { delete(item) }
                        )
                        .opacity(dimmed ? 0.72 : 1)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)

            Text(searchText.isEmpty ? "No tasks yet" : "No matching tasks")
                .font(.title3.weight(.semibold))

            Text(
                searchText.isEmpty
                ? "Add a task to start using the to-do flow."
                : "Try a different search or add a new task."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button(searchText.isEmpty ? "Add First Task" : "Add Task") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func statusPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func priorityRank(_ priority: ToDoPriority) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }

    private func toggle(_ item: ToDoItem) {
        guard let db else { return }
        var updated = item
        updated.isDone.toggle()
        updated.updatedAt = Date()
        _ = try? db.put(updated)
        ActivityLogging.append(
            db: db,
            type: updated.isDone ? .todoCompleted : .todoReopened,
            message: updated.isDone ? "Completed “\(updated.title)”" : "Reopened “\(updated.title)”",
            sourceTab: "To-Do List",
            sourceModel: "ToDoItem"
        )
    }

    private func delete(_ item: ToDoItem) {
        guard let db else { return }
        _ = try? db.delete(item)
        ActivityLogging.append(
            db: db,
            type: .todoDeleted,
            message: "Deleted to-do “\(item.title)”",
            sourceTab: "To-Do List",
            sourceModel: "ToDoItem"
        )

        if editingID == item.id {
            cancelEdit()
        }
    }

    private func commitEdit(for item: ToDoItem) {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let db, !trimmed.isEmpty else {
            cancelEdit()
            return
        }

        var updated = item
        updated.title = trimmed
        updated.notes = editingNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.priority = editingPriority
        updated.dueDate = editingHasDueDate ? editingDueDate : nil
        updated.updatedAt = Date()
        _ = try? db.put(updated)

        cancelEdit()
    }

    private func cancelEdit() {
        editingID = nil
        editingTitle = ""
        editingNotes = ""
        editingPriority = .medium
        editingHasDueDate = false
        editingDueDate = Date()
    }
}

struct ToDoCard: View {
    let item: ToDoItem
    var compact: Bool = false
    let isEditing: Bool

    @Binding var editingTitle: String
    @Binding var editingNotes: String
    @Binding var editingPriority: ToDoPriority
    @Binding var editingHasDueDate: Bool
    @Binding var editingDueDate: Date

    let onBeginEdit: () -> Void
    let onCommitEdit: () -> Void
    let onCancelEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 10) {
                if isEditing {
                    TextField("Task title", text: $editingTitle)
                        .textFieldStyle(.plain)
                        .font(.headline.weight(.semibold))
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(item.title)
                            .font(.headline)
                            .strikethrough(item.isDone)
                            .foregroundStyle(item.isDone ? .secondary : .primary)
                            .onTapGesture(count: 2, perform: onBeginEdit)

                        priorityBadge(item.priority)

                        if let dueDate = item.dueDate {
                            dueDateBadge(dueDate)
                        }

                        Spacer()
                    }
                }

                if isEditing {
                    TextField("Notes", text: $editingNotes, axis: .vertical)
                        .lineLimit(2...4)

                    HStack(spacing: 12) {
                        Picker("Priority", selection: $editingPriority) {
                            ForEach(ToDoPriority.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Due Date", isOn: $editingHasDueDate)
                            .toggleStyle(.switch)
                    }

                    if editingHasDueDate {
                        DatePicker("Due", selection: $editingDueDate, displayedComponents: .date)
                    }
                } else if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .onTapGesture(count: 2, perform: onBeginEdit)
                }
            }

            Spacer()

            if isEditing {
                HStack(spacing: 8) {
                    Button("Save", action: onCommitEdit)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                    Button("Cancel", action: onCancelEdit)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            } else {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(compact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(radius: 2, y: 1)
    }

    @ViewBuilder
    private func priorityBadge(_ priority: ToDoPriority) -> some View {
        Text(priority.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor(priority).opacity(0.15))
            .foregroundStyle(priorityColor(priority))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func dueDateBadge(_ date: Date) -> some View {
        Text(date.formatted(date: .abbreviated, time: .omitted))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.14))
            .foregroundStyle(.purple)
            .clipShape(Capsule())
    }

    private func priorityColor(_ priority: ToDoPriority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct AddToDoItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.blazeDBClient) private var db

    @State private var title = ""
    @State private var notes = ""
    @State private var priority: ToDoPriority
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    init(initialPriority: ToDoPriority = .medium) {
        _priority = State(initialValue: initialPriority)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task title", text: $title)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Details") {
                    Picker("Priority", selection: $priority) {
                        ForEach(ToDoPriority.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Add Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard let db, !trimmed.isEmpty else { return }

                        let now = Date()
                        var todo = ToDoItem(
                            title: trimmed,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                            priority: priority,
                            dueDate: hasDueDate ? dueDate : nil
                        )
                        todo.createdAt = now
                        todo.updatedAt = now
                        _ = try? db.put(todo)
                        ActivityLogging.append(
                            db: db,
                            type: .todoAdded,
                            message: "Added to-do “\(trimmed)”",
                            sourceTab: "To-Do List",
                            sourceModel: "ToDoItem"
                        )

                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 340)
    }
}
