//
//  ActivityLogView.swift
//  BlazeDBTESTAPP
//

import SwiftUI
import BlazeDB

struct ActivityLogView: View {
    @BlazeStorableQuery(kind: ActivityItem.self) private var eventsRaw: [ActivityItem]

    /// BlazeDB `main` exposes only `kind:` + optional `sortBy:` string on filtered queries; sort here for newest-first.
    private var events: [ActivityItem] {
        eventsRaw.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Log")
                        .font(.largeTitle.bold())
                    Text("Newest first · persisted in BlazeDB for audit-style review.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if events.isEmpty {
                    empty
                } else {
                    VStack(spacing: 0) {
                        ForEach(events, id: \.id) { row in
                            logRow(row)
                            if row.id != events.last?.id {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.windowBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 38))
                .foregroundStyle(.secondary)
            Text("No activity yet")
                .font(.title3.weight(.semibold))
            Text("Actions from other tabs and debug tools will show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func logRow(_ row: ActivityItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.timestamp.formatted(date: .abbreviated, time: .standard))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(row.message)
                    .font(.body)
                HStack(spacing: 8) {
                    Text(row.sourceTab)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                    Text(row.sourceModel)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(row.eventType.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
