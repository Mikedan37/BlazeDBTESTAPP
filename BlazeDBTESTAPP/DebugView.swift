//
//  DebugView.swift
//  BlazeDBTESTAPP
//

import SwiftUI
import BlazeDB

struct DebugView: View {
    @Environment(\.blazeDBClient) private var db
    @BlazeStorableQuery private var checkItems: [CheckItem]
    @BlazeStorableQuery private var bugs: [BugItem]
    @BlazeStorableQuery private var todos: [ToDoItem]
    @BlazeStorableQuery private var notes: [NoteItem]
    @BlazeStorableQuery private var activity: [ActivityItem]

    @State private var lastAction: String = "No actions yet."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug & Inspector")
                        .font(.largeTitle.bold())
                    Text("Validation tools and database introspection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                sectionTitle("About")
                Text(
                    "Internal QA / showcase build—not a product roadmap. For a full description of what this harness proves, see “What this app is” on the Dashboard tab."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground())

                sectionTitle("Database")
                databaseSection

                sectionTitle("Last action")
                Text(lastAction)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground())

                sectionTitle("Demo data")
                demoButtons

                sectionTitle("Reset data")
                resetButtons

                sectionTitle("Quick validation")
                Text(
                    "Use seed + clear cycles to confirm deletes, queries, and activity logging stay consistent. After relaunch, confirm persistence with the checklist in the project README (items, edits, settings, activity)."
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground())
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private var databaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            labeledRow("Name", db?.name ?? "—")
            labeledRow("Checklist rows", "\(checkItems.count)")
            labeledRow("Bug rows", "\(bugs.count)")
            labeledRow("To-do rows", "\(todos.count)")
            labeledRow("Note rows", "\(notes.count)")
            labeledRow("Activity rows", "\(activity.count)")
        }
        .padding(16)
        .background(cardBackground())
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3.weight(.semibold))
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body.weight(.medium))
        }
    }

    private var demoButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button("Seed Checklist") { run { try DemoDataSeeder.seedChecklist(db: $0) } } 
                Button("Seed Bugs") { run { try DemoDataSeeder.seedBugs(db: $0) } }
            }
            HStack(spacing: 10) {
                Button("Seed To-Dos") { run { try DemoDataSeeder.seedTodos(db: $0) } }
                Button("Seed Notes") { run { try DemoDataSeeder.seedNotes(db: $0) } }
            }
            Button("Seed All Demo Data") {
                guard let db else {
                    lastAction = "No database client in environment."
                    return
                }
                do {
                    let r = try DemoDataSeeder.seedAll(db: db)
                    lastAction =
                        "Seeded all: checklist \(r.checklist), bugs \(r.bugs), todos \(r.todos), notes \(r.notes)"
                } catch {
                    lastAction = "Error: \(error.localizedDescription)"
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Clear all + seed (screenshot demo)") {
                guard let db else {
                    lastAction = "No database client in environment."
                    return
                }
                do {
                    _ = try DemoDataSeeder.resetAndSeedForScreenshots(db: db)
                    lastAction =
                        "Screenshot demo ready: full reset, default settings row, polished seed (check off Milk, one resolved bug, one completed todo)."
                } catch {
                    lastAction = "Error: \(error.localizedDescription)"
                }
            }
            .help("One trusted path: wipe data, restore AppSettings defaults, re-seed everything for presentable tabs.")
        }
        .padding(16)
        .background(cardBackground())
    }

    private var resetButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button("Clear Checklist", role: .destructive) { run { try DemoDataSeeder.clearChecklist(db: $0) } }
                Button("Clear Bugs", role: .destructive) { run { try DemoDataSeeder.clearBugs(db: $0) } }
            }
            HStack(spacing: 10) {
                Button("Clear To-Dos", role: .destructive) { run { try DemoDataSeeder.clearTodos(db: $0) } }
                Button("Clear Notes", role: .destructive) { run { try DemoDataSeeder.clearNotes(db: $0) } }
            }
            HStack(spacing: 10) {
                Button("Clear Activity Log", role: .destructive) { run { try DemoDataSeeder.clearActivityLog(db: $0) } }
            }
            Button("Clear All Data", role: .destructive) { run { try DemoDataSeeder.clearAll(db: $0) } }
                .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(cardBackground())
    }

    private func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.windowBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private func run(_ work: (BlazeDBClient) throws -> Int) {
        guard let db else {
            lastAction = "No database client in environment."
            return
        }
        do {
            let n = try work(db)
            lastAction = "OK · affected \(n) row(s) · \(Date().formatted(date: .omitted, time: .standard))"
        } catch {
            lastAction = "Error: \(error.localizedDescription)"
        }
    }

}
