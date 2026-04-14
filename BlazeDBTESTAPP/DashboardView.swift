//
//  DashboardView.swift
//  BlazeDBTESTAPP
//

import SwiftUI
import BlazeDB

struct DashboardView: View {
    @BlazeStorableQuery(kind: CheckItem.self) private var checkItems: [CheckItem]
    @BlazeStorableQuery(kind: BugItem.self) private var bugs: [BugItem]
    @BlazeStorableQuery(kind: ToDoItem.self) private var todos: [ToDoItem]

    private var totalChecklist: Int { checkItems.count }
    private var uncheckedChecklist: Int { checkItems.filter { !$0.isChecked }.count }
    private var openBugs: Int { bugs.filter { !$0.isResolved }.count }
    private var resolvedBugs: Int { bugs.filter { $0.isResolved }.count }
    private var openTodos: Int { todos.filter { !$0.isDone }.count }
    private var completedTodos: Int { todos.filter { $0.isDone }.count }
    private var highPriorityOpenTodos: Int {
        todos.filter { !$0.isDone && $0.priority == .high }.count
    }

    private var recentCheck: CheckItem? {
        checkItems.max(by: { $0.touchedAt < $1.touchedAt })
    }

    private var recentBug: BugItem? {
        bugs.max(by: { $0.touchedAt < $1.touchedAt })
    }

    private var recentTodo: ToDoItem? {
        todos.max(by: { $0.touchedAt < $1.touchedAt })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BlazeDB Dashboard")
                        .font(.largeTitle.bold())
                    Text("Live counts across all models in the shared database.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                aboutCard

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 200), spacing: 14)],
                    spacing: 14
                ) {
                    summaryCard(title: "Checklist items", value: totalChecklist, caption: "All items", color: .blue)
                    summaryCard(title: "Unchecked", value: uncheckedChecklist, caption: "Still open", color: .cyan)
                    summaryCard(title: "Open bugs", value: openBugs, caption: "Needs attention", color: .orange)
                    summaryCard(title: "Resolved bugs", value: resolvedBugs, caption: "Shipped fixes", color: .green)
                    summaryCard(title: "Open to-dos", value: openTodos, caption: "In progress", color: .indigo)
                    summaryCard(title: "Completed to-dos", value: completedTodos, caption: "Done", color: .mint)
                    summaryCard(title: "High-priority to-dos", value: highPriorityOpenTodos, caption: "Open · High", color: .red)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Recently touched")
                        .font(.title3.weight(.semibold))

                    VStack(spacing: 12) {
                        recentRow(
                            label: "Checklist",
                            title: recentCheck?.title ?? "—",
                            date: recentCheck?.touchedAt
                        )
                        recentRow(
                            label: "Bug",
                            title: recentBug?.title ?? "—",
                            date: recentBug?.touchedAt
                        )
                        recentRow(
                            label: "To-do",
                            title: recentTodo?.title ?? "—",
                            date: recentTodo?.touchedAt
                        )
                    }
                }
            }
            .frame(maxWidth: 880, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What this app is")
                .font(.headline.weight(.semibold))
            Text(
                "This is a BlazeDB validation harness: multiple model types, SwiftUI integration patterns, persistent settings, activity logging, and debug tooling—all on one shared database. Use it to dogfood the API, QA persistence, and show newcomers something real—not a one-screen CRUD toy."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    private func summaryCard(title: String, value: Int, caption: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }

    private func recentRow(label: String, title: String, date: Date?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .leading)
            Text(title)
                .font(.body.weight(.medium))
                .lineLimit(1)
            Spacer()
            if let date {
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
