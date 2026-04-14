//
//  BlazeStorable+App.swift
//  BlazeDBTESTAPP
//

import BlazeDB

extension BlazeStorable {
    /// Namespace string used by BlazeDB for this storable type (matches persisted `_blazeKind`).
    static var blazeNamespace: String {
        BlazeRecordKind.normalizedName(for: Self.self)
    }
}
