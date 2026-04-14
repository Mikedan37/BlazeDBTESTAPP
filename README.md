# BlazeDBTESTAPP

macOS SwiftUI app that serves as a **test harness**, **example integration**, and **dogfooding surface** for [BlazeDB](../BlazeDB). It is not a product; it is intentionally scoped to prove the embedded database in realistic UI patterns.

## What it demonstrates

- Multiple `BlazeStorable` model types in **one** opened database (`BlazeDB.open` + `.blazeDBEnvironment`)
- List, grid, dashboard aggregation, notes, settings, activity log, and debug seeding
- Create / read / update / delete through the shared `BlazeDBClient`
- Persistent app settings (`AppSettings`) and append-only style auditing (`ActivityItem`)
- Debug tooling: per-type clear, full reset, and a **single “screenshot demo” path** (`resetAndSeedForScreenshots`) that clears everything, restores default settings, and re-seeds polished demo data

## Repository layout

| Location | Role |
|----------|------|
| This directory | Xcode project + app sources |
| [`../BlazeDB`](../BlazeDB) | BlazeDB Swift package (local SwiftPM dependency) |

## Quick QA (persistence)

Boring but important. After any change that touches storage:

1. Run the app, add or edit a checklist item, bug, to-do, and note; toggle settings.
2. **Quit the app completely** (not just close the window).
3. Relaunch and confirm:
   - **Items** still exist
   - **Edits** survived
   - **Settings** match what you left
   - **Activity log** still shows prior events

Optional: use **Debug → Clear all + seed (screenshot demo)** for a known-good baseline, then repeat the check.

## Screenshot / demo packaging

1. Open **Debug** and click **Clear all + seed (screenshot demo)**. That is the one reset path meant for a clean, presentable state: full wipe, default `AppSettings` row, full seed with varied states (e.g. one checked checklist item, one resolved bug, one completed todo).
2. Walk tabs in any order; **Activity** will contain seed/clear history—enough for a realistic log.
3. Export images if you want release assets: drop files under [`docs/screenshots/`](docs/screenshots/README.md) and reference them from the main BlazeDB docs as needed.

## Building

Open `BlazeDBTESTAPP.xcodeproj` in Xcode, select the **BlazeDBTESTAPP** macOS target, and run. The BlazeDB package resolves from `../BlazeDB` (sibling checkout).

## When is this “done”?

Per project intent: tabs work, seed/reset is trustworthy, persistence survives relaunch, UI is screenshot-worthy, and the app helps explain BlazeDB and surface API friction—without turning into a second product.
