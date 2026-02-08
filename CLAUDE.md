# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Blockalicious is a Safari content blocker for macOS and iOS. Users manage a list of blocked domains in the app; a Safari extension enforces the blocks. The app and extension share data via App Groups.

## Build

This is a native Xcode project (`Blockalicious.xcodeproj`), not a Swift Package. There is no CLI build configured — build from Xcode using the **Blockalicious** (macOS) or **Blockalicious-iOS** schemes. No tests exist.

## Architecture

### Targets (5 total)

- **BlockaliciousKit** — Shared framework containing all platform-agnostic logic (models, view models, persistence, Safari integration). Linked by all other targets.
- **Blockalicious** — macOS app. SwiftUI views only.
- **Blockalicious-iOS** — iOS app. SwiftUI views only.
- **Content Blocker** — macOS Safari content blocker extension.
- **Content Blocker-iOS** — iOS Safari content blocker extension.

### Data Flow

1. User edits domains in the app UI → `BlockedDomainsVim` (ObservableObject) manages the list
2. `BlockedDomainsVim.save()` writes `Domains.json` to the App Group container and calls `BlockerListWriter.write()` to generate `BlockList.json` (Safari's content blocker format)
3. `SFContentBlockerManager.reloadContentBlocker()` tells Safari to pick up the new rules
4. The Content Blocker extension serves `BlockList.json` from the shared container when Safari requests it

### App Group Identifiers

These differ by platform and are defined in `BlockerListWriter`:
- macOS: `BFJQQT3YDX.Blockalicious`
- iOS: `group.BFJQQT3YDX.Blockalicious`

### Xcode Project Structure

The project uses **PBXFileSystemSynchronizedRootGroup** — files are automatically compiled into the target that owns their directory. Cross-target file sharing uses `membershipExceptions` in the pbxproj (e.g., `DomainsPreseed.json` from `Blockalicious/Assets/` is shared to the iOS target). Moving files between directories changes their target membership automatically.

### Key Conventions

- Platform-specific code uses `#if os(iOS)` / `#if os(macOS)` (see `BlockerListWriter.swift`)
- All public API in `BlockaliciousKit` must have explicit `public` access modifiers
- `BlockaliciousKit` has `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` — if `@Published` properties cause build issues, this can be set to `NO`
- The Content Blocker extensions link against `BlockaliciousKit` but do NOT embed it — the host app embeds the framework
- `DomainsPreseed.json` must stay in the app bundles (not the framework) because it's loaded via `Bundle.main`
