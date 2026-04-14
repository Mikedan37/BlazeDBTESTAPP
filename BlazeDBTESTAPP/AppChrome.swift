//
//  AppChrome.swift
//  BlazeDBTESTAPP
//

import SwiftUI

extension AppAccentPreference {
    var swiftUIColor: Color? {
        switch self {
        case .system: return nil
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        }
    }
}
