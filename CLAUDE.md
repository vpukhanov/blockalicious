# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

This is an Xcode project (no Package.swift at root). Build and run via Xcode or:

```bash
# Build macOS app
xcodebuild -scheme Blockalicious -destination 'platform=macOS' build

# Build iOS app
xcodebuild -scheme Blockalicious-iOS -destination 'generic/platform=iOS' build

# Build macOS content blocker extension
xcodebuild -scheme "Content Blocker" -destination 'platform=macOS' build

# Build iOS content blocker extension
xcodebuild -scheme "Content Blocker-iOS" -destination 'generic/platform=iOS' build
```

There are no tests in this project.

## Architecture

Blockalicious is a Safari content blocker for macOS and iOS. Users manage a list of domains to block; the app generates a Safari content blocker JSON rule file that the Safari extension reads.

### Targets & Structure

- **BlockaliciousKit** — Shared framework (used by all targets). Contains the data model (`BLDomain`), view model (`BLViewModel`), storage (`DomainStorage`), favicon discovery (`FaviconService`), JSON decoding helpers, and platform constants (`AppConstant`).
- **Blockalicious** — macOS SwiftUI app. Entry point: `BlockaliciousApp.swift`.
- **Blockalicious-iOS** — iOS SwiftUI app. Entry point: `Blockalicious_iOSApp.swift`. Has its own `ContentView` and `ExtensionDisabledView` tailored for iOS.
- **Content Blocker** / **Content Blocker-iOS** — Safari Content Blocker extensions (macOS/iOS). They read `BlockList.json` from the shared app group container.

### Data Flow

1. `BLViewModel` loads domains from the app group container (`Domains.json`) or falls back to `DomainsPreseed.json` (bundled in BlockaliciousKit).
2. User edits are auto-saved via a Combine `$domains` pipeline (debounced 0.5s).
3. On save, `DomainStorage` writes two files to the app group container:
   - `Domains.json` — the full domain list (for the app to reload later)
   - `BlockList.json` — Safari content blocker format (consumed by the extension)
4. After writing, it calls `SFContentBlockerManager.reloadContentBlocker` to notify Safari.

### Key Details

- App group identifier differs by platform: `group.BFJQQT3YDX.Blockalicious` (iOS) vs `BFJQQT3YDX.Blockalicious` (macOS) — see `AppConstant`.
- Domain names use wildcard prefix convention (e.g., `*facebook.com`) to match subdomains. The `basename` property strips leading non-alphanumeric characters for favicon lookups.
- Safari requires a non-empty `if-domain` list — when no domains are blocked, a dummy domain (`non1.existent2.domain3`) is used as a workaround.
- `DomainStorage` is an `actor`; `FaviconService` is an `actor`. `BLViewModel` is `@MainActor`.

### Dependencies (via SPM)

- **FaviconFinder** — discovers favicon URLs for blocked domains
- **CachedAsyncImage** — async image loading with caching for favicons in the UI
