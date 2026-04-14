//
//  DemoDataSeeder.swift
//  BlazeDBTESTAPP
//

import Foundation
import BlazeDB

enum DemoDataSeeder {

    // MARK: - Seed

    static func seedChecklist(db: BlazeDBClient) throws -> Int {
        let samples = ["Milk", "Eggs", "Bread", "Coffee Beans"]
        let now = Date()
        for (index, title) in samples.enumerated() {
            var item = CheckItem(title: title)
            item.createdAt = now
            item.updatedAt = now
            if index == 0 {
                item.isChecked = true
            }
            try db.put(item)
        }
        ActivityLogging.append(
            db: db,
            type: .demoSeedChecklist,
            message: "Seeded \(samples.count) checklist items",
            sourceTab: "Debug",
            sourceModel: "CheckItem"
        )
        return samples.count
    }

    static func seedBugs(db: BlazeDBClient) throws -> Int {
        let samples: [(String, String, BugSeverity)] = [
            (
                "Crash on startup when settings are nil",
                "Repro: launch with a fresh database before Settings creates defaults.",
                .critical
            ),
            (
                "Wrong padding in dashboard summary card",
                "Cards look tight against the trailing edge at certain window widths.",
                .medium
            ),
            (
                "Toggle animation stutters on first load",
                "Only the first checkbox interaction; subsequent toggles are smooth.",
                .low
            ),
        ]
        let now = Date()
        for (index, (title, details, severity)) in samples.enumerated() {
            var bug = BugItem(title: title, details: details, severity: severity)
            bug.createdAt = now
            bug.updatedAt = now
            if index == 1 {
                bug.isResolved = true
            }
            try db.put(bug)
        }
        ActivityLogging.append(
            db: db,
            type: .demoSeedBugs,
            message: "Seeded \(samples.count) bug items",
            sourceTab: "Debug",
            sourceModel: "BugItem"
        )
        return samples.count
    }

    static func seedTodos(db: BlazeDBClient) throws -> Int {
        let samples: [(String, ToDoPriority)] = [
            ("Write README examples", .medium),
            ("Add search to bug tracker", .high),
            ("Polish settings persistence", .low),
        ]
        let now = Date()
        for (title, priority) in samples {
            var todo = ToDoItem(title: title, priority: priority)
            todo.createdAt = now
            todo.updatedAt = now
            if title == "Polish settings persistence" {
                todo.isDone = true
            }
            try db.put(todo)
        }
        ActivityLogging.append(
            db: db,
            type: .demoSeedTodos,
            message: "Seeded \(samples.count) to-do items",
            sourceTab: "Debug",
            sourceModel: "ToDoItem"
        )
        return samples.count
    }

    static func seedNotes(db: BlazeDBClient) throws -> Int {
        let samples: [(String, String)] = [
            ("BlazeDB API ideas", "Explore aggregate helpers and typed batch upserts for dashboards."),
            ("Things found while dogfooding", "Note flicker when switching tabs if queries reload simultaneously."),
            ("SwiftUI integration notes", "Prefer one @BlazeStorableQuery per screen; share the same environment client."),
        ]
        let now = Date()
        for (title, body) in samples {
            var note = NoteItem(title: title, body: body)
            note.createdAt = now
            note.updatedAt = now
            try db.put(note)
        }
        ActivityLogging.append(
            db: db,
            type: .demoSeedNotes,
            message: "Seeded \(samples.count) notes",
            sourceTab: "Debug",
            sourceModel: "NoteItem"
        )
        return samples.count
    }

    static func seedAll(db: BlazeDBClient) throws -> (checklist: Int, bugs: Int, todos: Int, notes: Int) {
        let c = try seedChecklist(db: db)
        let b = try seedBugs(db: db)
        let t = try seedTodos(db: db)
        let n = try seedNotes(db: db)
        ActivityLogging.append(
            db: db,
            type: .demoSeedAll,
            message: "Seeded all demo data (checklist \(c), bugs \(b), todos \(t), notes \(n))",
            sourceTab: "Debug",
            sourceModel: "Mixed"
        )
        return (c, b, t, n)
    }

    /// Single trusted path for demos and screenshots: wipe everything, restore default settings, then seed the full polished demo (mixed checklist/bug/todo states for richer dashboard cards).
    static func resetAndSeedForScreenshots(db: BlazeDBClient) throws -> Int {
        let clearedTotal = try clearAll(db: db)
        try db.put(AppSettings())
        _ = try seedAll(db: db)
        return clearedTotal
    }

    // MARK: - Clear

    static func clearChecklist(db: BlazeDBClient) throws -> Int {
        let rows: [CheckItem] = try db.query(CheckItem.blazeNamespace).all()
        for row in rows {
            try db.delete(row)
        }
        ActivityLogging.append(
            db: db,
            type: .dataClearedChecklist,
            message: "Cleared \(rows.count) checklist items",
            sourceTab: "Debug",
            sourceModel: "CheckItem"
        )
        return rows.count
    }

    static func clearBugs(db: BlazeDBClient) throws -> Int {
        let rows: [BugItem] = try db.query(BugItem.blazeNamespace).all()
        for row in rows {
            try db.delete(row)
        }
        ActivityLogging.append(
            db: db,
            type: .dataClearedBugs,
            message: "Cleared \(rows.count) bug items",
            sourceTab: "Debug",
            sourceModel: "BugItem"
        )
        return rows.count
    }

    static func clearTodos(db: BlazeDBClient) throws -> Int {
        let rows: [ToDoItem] = try db.query(ToDoItem.blazeNamespace).all()
        for row in rows {
            try db.delete(row)
        }
        ActivityLogging.append(
            db: db,
            type: .dataClearedTodos,
            message: "Cleared \(rows.count) to-do items",
            sourceTab: "Debug",
            sourceModel: "ToDoItem"
        )
        return rows.count
    }

    static func clearNotes(db: BlazeDBClient) throws -> Int {
        let rows: [NoteItem] = try db.query(NoteItem.blazeNamespace).all()
        for row in rows {
            try db.delete(row)
        }
        ActivityLogging.append(
            db: db,
            type: .dataClearedNotes,
            message: "Cleared \(rows.count) notes",
            sourceTab: "Debug",
            sourceModel: "NoteItem"
        )
        return rows.count
    }

    static func clearActivityLog(db: BlazeDBClient) throws -> Int {
        let rows: [ActivityItem] = try db.query(ActivityItem.blazeNamespace).all()
        for row in rows {
            try db.delete(row)
        }
        return rows.count
    }

    /// Removes all app data rows including settings and activity. Settings are recreated by the Settings tab on next visit.
    static func clearAll(db: BlazeDBClient) throws -> Int {
        let c = try deleteAll(CheckItem.self, db: db)
        let b = try deleteAll(BugItem.self, db: db)
        let t = try deleteAll(ToDoItem.self, db: db)
        let n = try deleteAll(NoteItem.self, db: db)
        let s = try deleteAll(AppSettings.self, db: db)
        let a = try deleteAll(ActivityItem.self, db: db)

        ActivityLogging.append(
            db: db,
            type: .dataClearedAll,
            message:
                "Cleared all data (checklist \(c), bugs \(b), todos \(t), notes \(n), activity \(a), settings \(s))",
            sourceTab: "Debug",
            sourceModel: "Mixed"
        )
        return c + b + t + n + a + s
    }

    private static func deleteAll<T: BlazeStorable>(_: T.Type, db: BlazeDBClient) throws -> Int {
        let rows: [T] = try db.query(T.blazeNamespace).all()
        for row in rows {
            try db.delete(row)
        }
        return rows.count
    }
}
