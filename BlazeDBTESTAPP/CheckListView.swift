//
//  CheckListView.swift
//  BlazeDBTESTAPP
//
//  Created by Michael Danylchuk on 4/13/26.
//
import SwiftUI
import BlazeDB

struct CheckItem: BlazeStorable {
    var id: UUID = UUID()
    var title: String
    var isChecked: Bool = false
    var createdAt: Date?
    var updatedAt: Date?

    var touchedAt: Date {
        max(createdAt ?? .distantPast, updatedAt ?? .distantPast)
    }
}

enum CheckListSortMode: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case alphabetical = "Alphabetical"
    case uncheckedFirst = "Unchecked First"

    var id: String { rawValue }
}

struct CheckListView: View {
    @Environment(\.blazeDBClient) private var db
    @BlazeStorableQuery private var items: [CheckItem]
    @BlazeStorableQuery(where: "id", equals: .uuid(AppSettings.singletonID)) private var settingsRows: [AppSettings]

    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var sortMode: CheckListSortMode = .uncheckedFirst

    @State private var editingID: UUID?
    @State private var editingTitle: String = ""

    private var settings: AppSettings {
        settingsRows.first ?? .default
    }

    private var rowSpacing: CGFloat {
        settings.compactMode ? 8 : 10
    }

    private var filteredItems: [CheckItem] {
        let base: [CheckItem]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            base = items
        } else {
            let query = searchText.lowercased()
            base = items.filter { $0.title.lowercased().contains(query) }
        }

        switch sortMode {
        case .manual:
            return base
        case .alphabetical:
            return base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .uncheckedFirst:
            return base.sorted {
                if $0.isChecked != $1.isChecked {
                    return !$0.isChecked && $1.isChecked
                }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
    }

    private var uncheckedItems: [CheckItem] {
        filteredItems.filter { !$0.isChecked }
    }

    private var checkedItems: [CheckItem] {
        filteredItems.filter { $0.isChecked }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                toolbarRow

                if filteredItems.isEmpty {
                    emptyState
                } else {
                    checklistSection(title: "Remaining", items: uncheckedItems)

                    if !checkedItems.isEmpty {
                        checklistSection(title: "Checked Off", items: checkedItems, dimmed: true)
                    }
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .toolbar {
            Button("Add") {
                showingAddSheet = true
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCheckItemView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Check List")
                .font(.largeTitle.bold())

            HStack(spacing: 12) {
                countPill(title: "\(uncheckedItems.count) Remaining", color: .blue)
                countPill(title: "\(checkedItems.count) Done", color: .green)
            }
        }
    }

    private var toolbarRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search checklist", text: $searchText)
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
                    ForEach(CheckListSortMode.allCases) { mode in
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
    private func checklistSection(title: String, items: [CheckItem], dimmed: Bool = false) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title3.weight(.semibold))

                VStack(spacing: rowSpacing) {
                    ForEach(items, id: \.id) { item in
                        CheckRow(
                            item: item,
                            compact: settings.compactMode,
                            isEditing: editingID == item.id,
                            editingTitle: $editingTitle,
                            onBeginEdit: {
                                editingID = item.id
                                editingTitle = item.title
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
            Image(systemName: "cart")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(searchText.isEmpty ? "No checklist items yet" : "No matching items")
                .font(.title3.weight(.semibold))

            Text(
                searchText.isEmpty
                ? "Add your first item to start using the checklist."
                : "Try a different search or add a new item."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button(searchText.isEmpty ? "Add First Item" : "Add Item") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func countPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func toggle(_ item: CheckItem) {
        guard let db else { return }
        var updated = item
        updated.isChecked.toggle()
        updated.updatedAt = Date()
        _ = try? db.put(updated)
        ActivityLogging.append(
            db: db,
            type: .checklistItemToggled,
            message: updated.isChecked ? "Checked “\(updated.title)”" : "Unchecked “\(updated.title)”",
            sourceTab: "Check List",
            sourceModel: "CheckItem"
        )
    }

    private func delete(_ item: CheckItem) {
        guard let db else { return }
        _ = try? db.delete(item)
        ActivityLogging.append(
            db: db,
            type: .checklistItemDeleted,
            message: "Deleted checklist item “\(item.title)”",
            sourceTab: "Check List",
            sourceModel: "CheckItem"
        )

        if editingID == item.id {
            cancelEdit()
        }
    }

    private func commitEdit(for item: CheckItem) {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let db else { return }

        if trimmed.isEmpty {
            cancelEdit()
            return
        }

        var updated = item
        updated.title = trimmed
        updated.updatedAt = Date()
        _ = try? db.put(updated)

        editingID = nil
        editingTitle = ""
    }

    private func cancelEdit() {
        editingID = nil
        editingTitle = ""
    }
}

struct CheckRow: View {
    let item: CheckItem
    var compact: Bool = false
    let isEditing: Bool
    @Binding var editingTitle: String

    let onBeginEdit: () -> Void
    let onCommitEdit: () -> Void
    let onCancelEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("Item title", text: $editingTitle)
                    .textFieldStyle(.plain)
                    .font(.body.weight(.medium))
                    .onSubmit(onCommitEdit)
            } else {
                Text(item.title)
                    .font(.body.weight(.medium))
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                    .onTapGesture(count: 2, perform: onBeginEdit)
            }

            Spacer()

            if isEditing {
                HStack(spacing: 10) {
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
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, compact ? 12 : 16)
        .padding(.vertical, compact ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct AddCheckItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.blazeDBClient) private var db

    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Checklist item", text: $title)
            }
            .navigationTitle("New Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard let db, !trimmed.isEmpty else { return }

                        let now = Date()
                        var item = CheckItem(title: trimmed)
                        item.createdAt = now
                        item.updatedAt = now
                        _ = try? db.put(item)
                        ActivityLogging.append(
                            db: db,
                            type: .checklistItemAdded,
                            message: "Added checklist item “\(trimmed)”",
                            sourceTab: "Check List",
                            sourceModel: "CheckItem"
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 380, minHeight: 160)
    }
}
