//
//  SettingsView.swift
//  BlazeDBTESTAPP
//

import SwiftUI
import BlazeDB

struct SettingsView: View {
    @Environment(\.blazeDBClient) private var db
    @BlazeStorableQuery(where: "id", equals: .uuid(AppSettings.singletonID)) private var rows: [AppSettings]

    var body: some View {
        Form {
            Section("Layout") {
                Toggle("Compact mode", isOn: Binding(
                    get: { snapshot().compactMode },
                    set: { newValue in
                        guard let db else { return }
                        var s = snapshot()
                        s.compactMode = newValue
                        try? db.put(s)
                        ActivityLogging.append(
                            db: db,
                            type: .settingsChanged,
                            message: "Compact mode → \(newValue ? "on" : "off")",
                            sourceTab: "Settings",
                            sourceModel: "AppSettings"
                        )
                    }
                ))
                Picker("Accent", selection: accentBinding()) {
                    ForEach(AppAccentPreference.allCases) { accent in
                        Text(accent.displayName).tag(accent)
                    }
                }
            }

            Section("Checklist & bugs") {
                Toggle("Show resolved bugs", isOn: Binding(
                    get: { snapshot().showResolvedBugs },
                    set: { newValue in
                        guard let db else { return }
                        var s = snapshot()
                        s.showResolvedBugs = newValue
                        try? db.put(s)
                        ActivityLogging.append(
                            db: db,
                            type: .settingsChanged,
                            message: "Show resolved bugs → \(newValue ? "on" : "off")",
                            sourceTab: "Settings",
                            sourceModel: "AppSettings"
                        )
                    }
                ))
            }

            Section("To-do list") {
                Toggle("Show completed tasks", isOn: Binding(
                    get: { snapshot().showCompletedTasks },
                    set: { newValue in
                        guard let db else { return }
                        var s = snapshot()
                        s.showCompletedTasks = newValue
                        try? db.put(s)
                        ActivityLogging.append(
                            db: db,
                            type: .settingsChanged,
                            message: "Show completed tasks → \(newValue ? "on" : "off")",
                            sourceTab: "Settings",
                            sourceModel: "AppSettings"
                        )
                    }
                ))
                Picker("Default new task priority", selection: priorityBinding()) {
                    ForEach(ToDoPriority.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
            }

            Section {
                Text("Preferences are stored in BlazeDB as a single AppSettings record.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: 520, alignment: .leading)
        .frame(maxWidth: .infinity)
        .padding(24)
        .onAppear(perform: ensureDefaultSettings)
    }

    private func snapshot() -> AppSettings {
        rows.first ?? AppSettings.default
    }

    private func ensureDefaultSettings() {
        guard let db, rows.isEmpty else { return }
        try? db.put(AppSettings())
    }

    private func priorityBinding() -> Binding<ToDoPriority> {
        Binding(
            get: { snapshot().defaultTodoPriority },
            set: { newValue in
                guard let db else { return }
                var s = snapshot()
                s.defaultTodoPriority = newValue
                try? db.put(s)
                ActivityLogging.append(
                    db: db,
                    type: .settingsChanged,
                    message: "Default to-do priority → \(newValue.rawValue)",
                    sourceTab: "Settings",
                    sourceModel: "AppSettings"
                )
            }
        )
    }

    private func accentBinding() -> Binding<AppAccentPreference> {
        Binding(
            get: { snapshot().accentPreference },
            set: { newValue in
                guard let db else { return }
                var s = snapshot()
                s.accentPreference = newValue
                try? db.put(s)
                ActivityLogging.append(
                    db: db,
                    type: .settingsChanged,
                    message: "Accent → \(newValue.displayName)",
                    sourceTab: "Settings",
                    sourceModel: "AppSettings"
                )
            }
        )
    }
}
