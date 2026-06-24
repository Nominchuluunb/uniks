# Spec: Two-Screen Onboarding Flow

**Date:** 2026-06-24  
**Scope:** v1.0, Phase 3 polish  
**Status:** Approved for implementation

## Goal

Show a short, skippable onboarding flow on first launch so a new user understands the core interaction and the privacy promise within 60 seconds.

## Requirements

1. **Two pages**
   - **Page 1 — Capture:** Explain the QuickInput HUD.
     - macOS: *“Press Cmd + Shift + U anywhere to log a thought.”*
     - iOS: *“Tap + to log a thought.”*
   - **Page 2 — Privacy:** Explain that data stays on device and AI runs locally.

2. **First-launch only**
   - Track completion in `UserDefaults` under key `uniks.hasCompletedOnboarding`.
   - Show onboarding as a full-screen cover if not completed.
   - Mark complete when the user taps **Get Started**.

3. **Visual design**
   - Use large SF Symbols, bold titles, short subtitles, and a primary CTA.
   - Page indicator (dots) at the bottom.
   - No custom assets or colors.

4. **No functional changes**
   - Does not change engine, persistence, or parsing logic.

## Files to create/modify

- Create: `uniks/UI/Onboarding/OnboardingView.swift`
- Modify: `uniks/ContentView.swift` — conditionally present onboarding.
- Modify: `uniks/uniksApp.swift` — pass onboarding state/completion.

## Testing

- Unit tests: not required (pure UI change).
- Manual verification:
  1. Delete app / reset `uniks.hasCompletedOnboarding` to `false`.
  2. Launch app → onboarding appears.
  3. Swipe/click through both pages.
  4. Tap **Get Started** → onboarding dismisses and main UI appears.
  5. Relaunch app → onboarding does not appear again.
