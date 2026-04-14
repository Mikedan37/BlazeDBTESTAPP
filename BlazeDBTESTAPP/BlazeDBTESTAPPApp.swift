//
//  BlazeDBTESTAPPApp.swift
//  BlazeDBTESTAPP
//
//  Created by Michael Danylchuk on 4/9/26.
//

import SwiftUI
import BlazeDB

final class AppDatabase {
    static let shared = AppDatabase()
    let db = try! BlazeDB.open(name: "myapp", password: "Password123!")
}

@main
struct BlazeDBTESTAPPApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .blazeDBEnvironment(AppDatabase.shared.db)
        }
    }
}
