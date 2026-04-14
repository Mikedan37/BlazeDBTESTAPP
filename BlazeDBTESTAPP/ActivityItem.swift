//
//  ActivityItem.swift
//  BlazeDBTESTAPP
//

import Foundation
import BlazeDB

enum ActivityEventType: String, Codable {
    case checklistItemAdded
    case checklistItemDeleted
    case checklistItemToggled

    case bugAdded
    case bugDeleted
    case bugResolved
    case bugReopened

    case todoAdded
    case todoDeleted
    case todoCompleted
    case todoReopened

    case noteAdded
    case noteDeleted
    case noteUpdated
    case notePinToggled

    case settingsChanged

    case demoSeedChecklist
    case demoSeedBugs
    case demoSeedTodos
    case demoSeedNotes
    case demoSeedAll

    case dataClearedChecklist
    case dataClearedBugs
    case dataClearedTodos
    case dataClearedNotes
    case dataClearedActivity
    case dataClearedAll
}

struct ActivityItem: BlazeStorable {
    var id: UUID = UUID()
    var eventType: ActivityEventType
    var message: String
    var timestamp: Date = Date()
    var sourceTab: String
    var sourceModel: String
}

enum ActivityLogging {
    static func append(
        db: BlazeDBClient?,
        type: ActivityEventType,
        message: String,
        sourceTab: String,
        sourceModel: String
    ) {
        guard let db else { return }
        let row = ActivityItem(
            eventType: type,
            message: message,
            sourceTab: sourceTab,
            sourceModel: sourceModel
        )
        try? db.put(row)
    }
}
