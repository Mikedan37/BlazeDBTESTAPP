//
//  NotesView.swift
//  BlazeDBTESTAPP
//

import SwiftUI
import BlazeDB

struct NotesView: View {
    @Environment(\.blazeDBClient) private var db
    @BlazeStorableQuery private var notes: [NoteItem]

    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editingNote: NoteItem?

    private var filtered: [NoteItem] {
        let base: [NoteItem]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            base = notes
        } else {
            let q = searchText.lowercased()
            base = notes.filter {
                $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q)
            }
        }
        return base.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            return a.touchedAt > b.touchedAt
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                searchBar

                if filtered.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                        ForEach(filtered, id: \.id) { note in
                            NoteCard(note: note, onTap: { editingNote = note }, onTogglePin: { togglePin(note) }, onDelete: { delete(note) })
                        }
                    }
                }
            }
            .frame(maxWidth: 980, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .toolbar {
            Button("Add") { showingAdd = true }
        }
        .sheet(isPresented: $showingAdd) {
            NoteEditorSheet(mode: .add)
        }
        .sheet(item: $editingNote) { note in
            NoteEditorSheet(mode: .edit(note))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes")
                .font(.largeTitle.bold())
            Text("Longer-form text, pinning, and search — separate from bugs and to-dos.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search title or body", text: $searchText)
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
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No notes yet" : "No matches")
                .font(.title3.weight(.semibold))
            Text("Capture API ideas, dogfooding observations, or integration notes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Add Note") { showingAdd = true }
                .buttonStyle(.borderedProminent)
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

    private func togglePin(_ note: NoteItem) {
        guard let db else { return }
        var n = note
        n.isPinned.toggle()
        n.updatedAt = Date()
        try? db.put(n)
        ActivityLogging.append(
            db: db,
            type: .notePinToggled,
            message: n.isPinned ? "Pinned “\(n.title)”" : "Unpinned “\(n.title)”",
            sourceTab: "Notes",
            sourceModel: "NoteItem"
        )
    }

    private func delete(_ note: NoteItem) {
        guard let db else { return }
        try? db.delete(note)
        ActivityLogging.append(
            db: db,
            type: .noteDeleted,
            message: "Deleted note “\(note.title)”",
            sourceTab: "Notes",
            sourceModel: "NoteItem"
        )
    }
}

private struct NoteCard: View {
    let note: NoteItem
    let onTap: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Text(note.title)
                            .font(.headline.weight(.semibold))
                            .lineLimit(2)
                    }
                    if !note.body.isEmpty {
                        Text(note.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(5)
                    }
                }
                Spacer()
                Menu {
                    Button(note.isPinned ? "Unpin" : "Pin", action: onTogglePin)
                    Button("Edit", action: onTap)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .buttonStyle(.plain)
            }
            Text(note.touchedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .onTapGesture(count: 2, perform: onTap)
    }
}

private enum NoteEditorMode {
    case add
    case edit(NoteItem)
}

private struct NoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.blazeDBClient) private var db

    let mode: NoteEditorMode

    @State private var title: String = ""
    @State private var bodyText: String = ""

    private var editorTitle: String {
        switch mode {
        case .add: return "New Note"
        case .edit: return "Edit Note"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Body", text: $bodyText, axis: .vertical)
                    .lineLimit(8...20)
            }
            .navigationTitle(editorTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 360)
        .onAppear {
            if case .edit(let n) = mode {
                title = n.title
                bodyText = n.body
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let db, !trimmedTitle.isEmpty else { return }
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()

        switch mode {
        case .add:
            var n = NoteItem(title: trimmedTitle, body: trimmedBody)
            n.createdAt = now
            n.updatedAt = now
            try? db.put(n)
            ActivityLogging.append(
                db: db,
                type: .noteAdded,
                message: "Added note “\(trimmedTitle)”",
                sourceTab: "Notes",
                sourceModel: "NoteItem"
            )
        case .edit(let original):
            var n = original
            n.title = trimmedTitle
            n.body = trimmedBody
            n.updatedAt = now
            try? db.put(n)
            ActivityLogging.append(
                db: db,
                type: .noteUpdated,
                message: "Updated note “\(trimmedTitle)”",
                sourceTab: "Notes",
                sourceModel: "NoteItem"
            )
        }
        dismiss()
    }
}
