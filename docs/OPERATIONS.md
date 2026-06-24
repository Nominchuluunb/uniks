# Uniks Operations Guide

Exact commands for building, testing, linting, screenshots, and icon generation.

## Build

### macOS

```bash
xcodebuild -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -skipMacroValidation
```

### iOS Simulator

```bash
xcodebuild -project uniks.xcodeproj -scheme uniks -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -skipMacroValidation
```

## Test

### macOS (recommended for CI)

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -skipMacroValidation -enableCodeCoverage NO
```

`-enableCodeCoverage NO` is required because the `yyjson` package fails to link with profiling instrumentation.

### iOS Simulator

```bash
xcodebuild test -project uniks.xcodeproj -scheme uniks -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -skipMacroValidation -enableCodeCoverage NO
```

## Lint

Run from the repo root:

```bash
swiftlint lint --config .swiftlint.yml
```

For strict mode (treats warnings as failures):

```bash
swiftlint lint --config .swiftlint.yml --strict
```

## App icon generation

Requires Python with Pillow in the project virtual environment:

```bash
source .venv/bin/activate
python3 scripts/generate_app_icon.py
```

## App Store screenshots

Use the helper script:

```bash
./scripts/capture_screenshots.sh
```

See [`docs/screenshots/README.md`](screenshots/README.md) for details.

## First-time project setup

1. Install the `xcodeproj` Ruby gem:
   ```bash
   gem install xcodeproj
   ```
2. Link required SPM packages:
   ```bash
   ruby scripts/add_spm_dependencies.rb
   ```
3. Open `uniks.xcodeproj` in Xcode and resolve packages.
4. For on-device MLX builds, ensure the Metal toolchain is installed:
   ```bash
   xcodebuild -downloadComponent MetalToolchain
   ```

## Common troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `DNSServiceCreateDelegateConnection failed` when downloading a model | Local DNS service not running | Restart DNS: `sudo killall -HUP mDNSResponder`, reboot, or switch network. |
| Build errors about macros / `@Model` | Macro validation missing | Add `-skipMacroValidation` to the command. |
| Link failure with `yyjson` / profiling | Code coverage instrumentation | Add `-enableCodeCoverage NO`. |
| Simulator uses Mock engine | MLX requires Metal GPU | Expected; use a physical device for real MLX inference. |

## Release checklist

- [ ] All tests pass on macOS.
- [ ] SwiftLint passes.
- [ ] App icon regenerated if assets changed.
- [ ] Screenshots updated if UI changed.
- [ ] `CHANGELOG.md` updated.
