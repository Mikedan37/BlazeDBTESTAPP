//
//  MainTabView.swift
//  BlazeDBTESTAPP
//

import SwiftUI
import BlazeDB

struct MainTabView: View {
    @BlazeStorableQuery(kind: AppSettings.self, where: "id", equals: .uuid(AppSettings.singletonID)) private var settingsRows: [AppSettings]

    private var accentColor: Color? {
        settingsRows.first?.accentPreference.swiftUIColor
    }

    var body: some View {
        Group {
            if let accentColor {
                tabbed.tint(accentColor)
            } else {
                tabbed
            }
        }
    }

    private var tabbed: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.doc.horizontal") }

            CheckListView()
                .tabItem { Label("Check List", systemImage: "checklist") }

            BugTrackView()
                .tabItem { Label("Bug Tracker", systemImage: "ladybug") }

            ToDoListView()
                .tabItem { Label("To-Do List", systemImage: "checkmark.circle") }

            NotesView()
                .tabItem { Label("Notes", systemImage: "note.text") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }

            DebugView()
                .tabItem { Label("Debug", systemImage: "hammer") }

            ActivityLogView()
                .tabItem { Label("Activity Log", systemImage: "list.bullet.rectangle") }
        }
        .tabViewStyle(SidebarAdaptableTabViewStyle())
    }
}
