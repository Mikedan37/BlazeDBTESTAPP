//
//  AppSettings.swift
//  BlazeDBTESTAPP
//

import Foundation
import BlazeDB

enum AppAccentPreference: String, Codable, CaseIterable, Identifiable {
    case system
    case blue
    case purple
    case green

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .green: return "Green"
        }
    }
}

/// Single-row app preferences stored in BlazeDB (`id` is fixed).
struct AppSettings: BlazeStorable {
    static let singletonID = UUID(uuidString: "A0B1C2D3-E4F5-4678-9ABC-DEF012345678")!

    var id: UUID = AppSettings.singletonID
    var compactMode: Bool = false
    var showCompletedTasks: Bool = true
    var defaultTodoPriority: ToDoPriority = .medium
    var showResolvedBugs: Bool = true
    var accentPreference: AppAccentPreference = .system

    static var `default`: AppSettings { AppSettings() }
}
