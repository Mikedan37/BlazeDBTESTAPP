//
//  BugTrackView.swift
//  BlazeDBTESTAPP
//
//  Created by Michael Danylchuk on 4/13/26.
//
import SwiftUI
import BlazeDB

enum BugSeverity: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var id: String { rawValue }
}

enum BugSortMode: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case alphabetical = "Alphabetical"
    case severity = "Severity"

    var id: String { rawValue }
}

struct BugItem: BlazeStorable {
    var id: UUID = UUID()
    var title: String
    var details: String = ""
    var severity: BugSeverity = .medium
    var isResolved: Bool = false
    var createdAt: Date?
    var updatedAt: Date?

    var touchedAt: Date {
        max(createdAt ?? .distantPast, updatedAt ?? .distantPast)
    }
}

struct BugTrackView: View {
    @Environment(\.blazeDBClient) private var db
    @BlazeStorableQuery private var items: [BugItem]
    @BlazeStorableQuery(where: "id", equals: .uuid(AppSettings.singletonID)) private var settingsRows: [AppSettings]

    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var sortMode: BugSortMode = .severity

    @State private var editingID: UUID?
    @State private var editingTitle: String = ""
    @State private var editingDetails: String = ""
    @State private var editingSeverity: BugSeverity = .medium

    private var settings: AppSettings {
        settingsRows.first ?? .default
    }

    private var gridSpacing: CGFloat {
        settings.compactMode ? 12 : 16
    }

    private let columns = [
        GridItem(.adaptive(minimum: 280), spacing: 16)
    ]

    private var filteredItems: [BugItem] {
        let base: [BugItem]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            base = items
        } else {
            let query = searchText.lowercased()
            base = items.filter {
                $0.title.lowercased().contains(query) ||
                $0.details.lowercased().contains(query)
            }
        }

        switch sortMode {
        case .newest:
            return base
        case .alphabetical:
            return base.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .severity:
            return base.sorted {
                severityRank($0.severity) > severityRank($1.severity)
            }
        }
    }

    private var openItems: [BugItem] {
        filteredItems.filter { !$0.isResolved }
    }

    private var resolvedItems: [BugItem] {
        let resolved = filteredItems.filter { $0.isResolved }
        if settings.showResolvedBugs {
            return resolved
        }
        return []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                controlsRow

                if filteredItems.isEmpty {
                    emptyState
                } else {
                    section(title: "Open", items: openItems)

                    if !resolvedItems.isEmpty {
                        section(title: "Resolved", items: resolvedItems, dimmed: true)
                    }
                }
            }
            .frame(maxWidth: 980, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .toolbar {
            Button("Add") {
                showingAddSheet = true
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBugItemView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bug Tracker")
                .font(.largeTitle.bold())

            HStack(spacing: 12) {
                countPill(title: "\(openItems.count) Open", color: .orange)
                countPill(title: "\(resolvedItems.count) Resolved", color: .green)
            }
        }
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search bugs", text: $searchText)
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
                    ForEach(BugSortMode.allCases) { mode in
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
    private func section(title: String, items: [BugItem], dimmed: Bool = false) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title3.weight(.semibold))

                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(items, id: \.id) { item in
                        BugCardView(
                            item: item,
                            compact: settings.compactMode,
                            isEditing: editingID == item.id,
                            editingTitle: $editingTitle,
                            editingDetails: $editingDetails,
                            editingSeverity: $editingSeverity,
                            onBeginEdit: {
                                editingID = item.id
                                editingTitle = item.title
                                editingDetails = item.details
                                editingSeverity = item.severity
                            },
                            onCommitEdit: {
                                commitEdit(for: item)
                            },
                            onCancelEdit: {
                                cancelEdit()
                            },
                            onToggleResolved: {
                                toggleResolved(item)
                            },
                            onDelete: {
                                delete(item)
                            }
                        )
                        .opacity(dimmed ? 0.72 : 1)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "ladybug")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)

            Text(searchText.isEmpty ? "No bugs yet" : "No matching bugs")
                .font(.title3.weight(.semibold))

            Text(
                searchText.isEmpty
                ? "Add a bug to start testing the bug tracker flow."
                : "Try a different search or add a new bug."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button(searchText.isEmpty ? "Add First Bug" : "Add Bug") {
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

    private func severityRank(_ severity: BugSeverity) -> Int {
        switch severity {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }

    private func toggleResolved(_ item: BugItem) {
        guard let db else { return }

        var updated = item
        updated.isResolved.toggle()
        updated.updatedAt = Date()
        _ = try? db.put(updated)
        ActivityLogging.append(
            db: db,
            type: updated.isResolved ? .bugResolved : .bugReopened,
            message: updated.isResolved ? "Resolved “\(updated.title)”" : "Reopened “\(updated.title)”",
            sourceTab: "Bug Tracker",
            sourceModel: "BugItem"
        )
    }

    private func delete(_ item: BugItem) {
        guard let db else { return }
        _ = try? db.delete(item)
        ActivityLogging.append(
            db: db,
            type: .bugDeleted,
            message: "Deleted bug “\(item.title)”",
            sourceTab: "Bug Tracker",
            sourceModel: "BugItem"
        )

        if editingID == item.id {
            cancelEdit()
        }
    }

    private func commitEdit(for item: BugItem) {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let db, !trimmed.isEmpty else {
            cancelEdit()
            return
        }

        var updated = item
        updated.title = trimmed
        updated.details = editingDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.severity = editingSeverity
        updated.updatedAt = Date()
        _ = try? db.put(updated)

        cancelEdit()
    }

    private func cancelEdit() {
        editingID = nil
        editingTitle = ""
        editingDetails = ""
        editingSeverity = .medium
    }
}

struct BugCardView: View {
    let item: BugItem
    var compact: Bool = false
    let isEditing: Bool

    @Binding var editingTitle: String
    @Binding var editingDetails: String
    @Binding var editingSeverity: BugSeverity

    let onBeginEdit: () -> Void
    let onCommitEdit: () -> Void
    let onCancelEdit: () -> Void
    let onToggleResolved: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                if isEditing {
                    TextField("Bug title", text: $editingTitle)
                        .textFieldStyle(.plain)
                        .font(.headline.weight(.semibold))
                } else {
                    Text(item.title)
                        .font(.headline.weight(.semibold))
                        .strikethrough(item.isResolved)
                        .foregroundStyle(item.isResolved ? .secondary : .primary)
                        .onTapGesture(count: 2, perform: onBeginEdit)
                }

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            if isEditing {
                TextField("Details", text: $editingDetails, axis: .vertical)
                    .lineLimit(3...5)

                Picker("Severity", selection: $editingSeverity) {
                    ForEach(BugSeverity.allCases) { severity in
                        Text(severity.rawValue).tag(severity)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                if !item.details.isEmpty {
                    Text(item.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .onTapGesture(count: 2, perform: onBeginEdit)
                } else {
                    Text("No details")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack {
                severityBadge(item.severity)

                Text(item.isResolved ? "Resolved" : "Open")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((item.isResolved ? Color.green : Color.orange).opacity(0.15))
                    .foregroundStyle(item.isResolved ? .green : .orange)
                    .clipShape(Capsule())

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
                    Button(item.isResolved ? "Reopen" : "Resolve") {
                        onToggleResolved()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(compact ? 12 : 16)
        .frame(maxWidth: .infinity, minHeight: compact ? 170 : 190, alignment: .topLeading)
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
    private func severityBadge(_ severity: BugSeverity) -> some View {
        Text(severity.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severityColor(severity).opacity(0.15))
            .foregroundStyle(severityColor(severity))
            .clipShape(Capsule())
    }

    private func severityColor(_ severity: BugSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct AddBugItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.blazeDBClient) private var db

    @State private var title = ""
    @State private var details = ""
    @State private var severity: BugSeverity = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Bug") {
                    TextField("Bug title", text: $title)

                    TextField("Details", text: $details, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Severity") {
                    Picker("Severity", selection: $severity) {
                        ForEach(BugSeverity.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Bug")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard let db, !trimmed.isEmpty else { return }

                        let now = Date()
                        var bug = BugItem(
                            title: trimmed,
                            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                            severity: severity
                        )
                        bug.createdAt = now
                        bug.updatedAt = now
                        _ = try? db.put(bug)
                        ActivityLogging.append(
                            db: db,
                            type: .bugAdded,
                            message: "Added bug “\(trimmed)”",
                            sourceTab: "Bug Tracker",
                            sourceModel: "BugItem"
                        )

                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 460, minHeight: 300)
    }
}
