# Spec: App Icon, Metadata, and Screenshots

**Date:** 2026-06-24  
**Scope:** v1.0, Phase 3 polish  
**Status:** Approved for implementation

## Goal

Prepare the app for App Store submission by adding a generated app icon, creating App Store metadata files, and adding a UI-test-based screenshot script.

## Requirements

1. **App icon**
   - Generate a simple, recognizable icon for `Assets.xcassets/AppIcon.appiconset`.
   - Provide all required sizes for macOS and iOS.
   - Use a bold symbol on a colored rounded background.

2. **App Store metadata**
   - Create `fastlane/metadata/default/` style files:
     - `name.txt`
     - `subtitle.txt`
     - `description.txt`
     - `keywords.txt`
     - `support_url.txt`
     - `marketing_url.txt`
     - `privacy_url.txt`
   - Keep copy concise, privacy-focused, and beginner-friendly.

3. **Screenshot script**
   - Add a UI test target/scheme helper that captures screenshots for the App Store.
   - Because the project currently uses the built-in `uniksTests` unit-test bundle, add a separate `uniksUITests` target is out of scope; instead, add a runnable script that launches the app and uses `simctl`/`xcrun simctl io` for screenshots.
   - Document the manual screenshot workflow.

4. **No functional changes**
   - Does not change data models, engines, or the core logging loop.

## Files to create/modify

- Create: `scripts/generate_app_icon.py`
- Create: `scripts/AppIcon source files` (temporary PNGs)
- Modify: `uniks/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `fastlane/metadata/default/*.txt`
- Create: `scripts/capture_screenshots.sh`
- Create: `docs/screenshots/README.md`

## Testing

- Unit tests: not required.
- Manual verification:
  1. Run `scripts/generate_app_icon.py`.
  2. Build app → icon appears in Dock/Launchpad/Simulator.
  3. Review metadata files.
  4. Run screenshot script → captures main screens.
