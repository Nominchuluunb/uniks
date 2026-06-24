# Spec: Three-Screen Onboarding Flow

**Date:** 2026-06-24  
**Scope:** v1.0, Phase 3 polish  
**Status:** Approved for implementation

## Goal

Show a short, skippable onboarding flow on first launch so a new user understands the core interaction and the privacy promise within 60 seconds.

## Requirements

1. **Three pages**
   - **Page 1 — Welcome:** Explain the QuickInput HUD and natural-language capture.
     - macOS: *“Press Cmd + Shift + U anywhere to log a thought.”*
     - iOS: *“Tap + to log a thought.”*
   - **Page 2 — Setup:** Explain that on-device models are downloaded from Hugging Face for local NLP parsing.
   - **Page 3 — Downloading:** Show download progress while `LocalModelManager.download(_:)` fetches the default model. Dismiss onboarding when the download completes.

2. **First-launch only**
   - Track completion in `UserDefaults` under key `uniks.hasCompletedOnboarding`.
   - Show onboarding as a full-screen cover on iOS and a sheet on macOS if not completed.
   - Mark complete when the user finishes the download stage.

3. **Visual design**
   - Use large SF Symbols, bold titles, short subtitles, and a primary CTA.
   - Page indicator (capsule pills) at the top.
   - Use the design-system `MeshBackground` and brand gradient.

4. **No functional changes**
   - Does not change engine, persistence, or parsing logic.

## Files to create/modify

- Create: `uniks/UI/Onboarding/OnboardingView.swift`
- Create: `uniks/UI/Onboarding/OnboardingSubviews.swift`
- Modify: `uniks/ContentView.swift` — conditionally present onboarding.

## Testing

- Unit tests: not required (pure UI change).
- Manual verification:
  1. Delete app / reset `uniks.hasCompletedOnboarding` to `false`.
  2. Launch app → onboarding appears.
  3. Click through all three pages.
  4. Complete download → onboarding dismisses and main UI appears.
  5. Relaunch app → onboarding does not appear again.
