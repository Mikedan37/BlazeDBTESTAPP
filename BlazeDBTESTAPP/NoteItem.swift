//
//  NoteItem.swift
//  BlazeDBTESTAPP
//

import Foundation
import BlazeDB

struct NoteItem: BlazeStorable {
    var id: UUID = UUID()
    var title: String
    var body: String = ""
    var isPinned: Bool = false
    var createdAt: Date?
    var updatedAt: Date?

    var touchedAt: Date {
        max(createdAt ?? .distantPast, updatedAt ?? .distantPast)
    }
}
