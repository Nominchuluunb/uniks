# App Store Screenshots

This folder contains the final App Store screenshots.

## Capturing screenshots

Use the helper script to capture consistent screenshots from the iOS Simulator:

```bash
./scripts/capture_screenshots.sh
```

The script will:
1. Find or create an iPhone 16 Pro simulator.
2. Build the app for the simulator.
3. Install and launch it with onboarding skipped (`-skipOnboarding`).
4. Prompt you to switch tabs and capture each screen.
5. Save screenshots to `fastlane/screenshots/`.

## Required screenshots

| # | Screen | Notes |
|---|--------|-------|
| 1 | Events list | Shows a few logged events with parsed chips. |
| 2 | Dashboard | Shows category totals, daily trend, top tags, and activity. |
| 3 | Settings | Shows engine selector and privacy note. |

## Tips

- Use the **Mock** engine while capturing so events parse quickly.
- Log diverse events before capturing (e.g. fitness, reading, water).
- The script cleans the status bar (9:41, full battery, Wi-Fi) automatically.
