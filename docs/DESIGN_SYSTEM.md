# Uniks Design System

This document is the canonical reference for the Uniks visual design system. All UI code must use the tokens and components listed here. Do not implement custom styling inline.

## Philosophy

Clean native iOS/macOS. Use system materials, semantic colors, SF Symbols, and Apple-standard spacing. The app should feel like a system app that happens to be privacy-first.

## Tokens

All tokens live in `uniks/UI/DesignSystem/`.

### Spacing

Use `CGFloat.spacing(_:)` only.

| Token | Value | Use case |
|-------|-------|----------|
| `.xxxSmall` | 2 | Tiny gaps, micro-alignment. |
| `.xxSmall` | 4 | Tight internal padding (chip vertical padding). |
| `.xSmall` | 8 | Related elements, row internal spacing. |
| `.small` | 12 | Section gaps, card internal spacing. |
| `.medium` | 16 | Default padding, card padding. |
| `.large` | 20 | Major section gaps. |
| `.xLarge` | 24 | Onboarding page spacing. |
| `.xxLarge` | 32 | Large vertical rhythm. |
| `.xxxLarge` | 48 | Hero empty-state icon area. |

### Corner radii

Use `CGFloat.radius(_:)` for standard radii or `Radius.pill` for full rounding.

| Token | Value | Use case |
|-------|-------|----------|
| `.small` | 6 | Small bars, tiny surfaces. |
| `.medium` | 10 | Cards. |
| `.large` | 16 | Large sheets/panels. |
| `Radius.pill` | 999 | Chips, badges, capsules. |

### Colors

Use only these semantic colors and gradients. No literal colors or hardcoded `.opacity(...)` in views.

| Token | Maps to | Use case |
|-------|---------|----------|
| `Color.primaryLabel` | `.primary` | Primary text. |
| `Color.secondaryLabel` | `.secondary` | Secondary text, hints, axis labels. |
| `Color.accent` | `.accentColor` | Accent fills, charts, focused actions. |
| `Color.positive` | `.green` | Success, parsed, downloaded. |
| `Color.negative` | `.red` | Errors, failures, destructive actions. |
| `Color.warning` | `.orange` | Warnings, retry hints. |
| `Color.groupedBackground` | System grouped background | Lists, forms background. |
| `Color.secondaryGroupedBackground` | System secondary grouped / control background | Card background backing. |
| `Color.tertiaryGroupedBackground` | `.gray.opacity(0.08)` | Chips, tags. |
| `Color.separator` | `.gray.opacity(0.15)` | Dividers, card strokes. |
| `Color.separatorFaint` | `.gray.opacity(0.3)` | Subtle gridlines, faint borders. |
| `Color.separatorVeryFaint` | `.gray.opacity(0.2)` | Hairline borders. |
| `Color.secondaryLabelFaint` | `.secondary.opacity(0.2)` | Inactive indicators. |
| `Color.secondaryLabelMuted` | `.secondary.opacity(0.85)` | De-emphasized body text. |
| `Color.secondaryLabelSubtle` | `.secondary.opacity(0.8)` | Hint text. |

#### Brand palette

Onboarding and marketing visuals use the brand palette. Do not use raw `.blue`, `.purple`, `.red`, etc. in views.

| Token | Maps to | Use case |
|-------|---------|----------|
| `Color.brandBlue` | `.blue` | Primary brand accent, buttons, progress. |
| `Color.brandPurple` | `.purple` | Hero gradients, secondary brand. |
| `Color.brandOrange` | `.orange` | Logo gradient, warnings. |
| `Color.brandRed` | `.red` | Glow accents. |
| `Color.brandYellow` | `.yellow` | Category color mapping. |
| `Color.brandTeal` | `.teal` | Category color mapping. |
| `Color.brandBlueGlowStrong` | `.blue.opacity(0.12)` | Mesh background glows. |
| `Color.brandBlueGlowMedium` | `.blue.opacity(0.1)` | Sidebar status icon background. |
| `Color.brandBlueGlowSoft` | `.blue.opacity(0.08)` | Icon highlight backgrounds. |
| `Color.brandBlueBackground` | `.blue.opacity(0.04)` | Card/panel brand tint. |
| `Color.brandBlueBorder` | `.blue.opacity(0.12)` | Brand hairline borders. |
| `Color.brandBlueShadow` | `.blue.opacity(0.3)` | Primary button shadow. |
| `Color.brandBlueShadowSoft` | `.blue.opacity(0.2)` | Secondary button shadow. |
| `Color.brandPurpleGlowMedium` | `.purple.opacity(0.1)` | Mesh background glows. |
| `Color.brandPurpleMuted` | `.purple.opacity(0.5)` | Hero text accents. |
| `Color.brandRedGlowSoft` | `.red.opacity(0.08)` | Mesh background glows. |

#### State and surface variants

| Token | Maps to | Use case |
|-------|---------|----------|
| `Color.onAccent` | `.white` | Text on accent-filled buttons. |
| `Color.accentSubtle` | `.accent.opacity(0.08)` | Selected row backgrounds, category chips. |
| `Color.accentSoft` | `.accent.opacity(0.12)` | Secondary accent buttons, ID badges. |
| `Color.accentMuted` | `.accent.opacity(0.4)` | Hover stroke emphasis. |
| `Color.accentGlow` | `.accent.opacity(0.2)` | Empty-state icon glow. |
| `Color.positiveSubtle` | `.green.opacity(0.08)` | Value chip backgrounds. |
| `Color.negativeSubtle` | `.red.opacity(0.08)` | Destructive chip/button backgrounds. |
| `Color.tertiaryGroupedBackgroundFaint` | `.tertiaryGroupedBackground.opacity(0.5)` | Hover backgrounds. |
| `Color.elevatedBackground` | `.white` | Onboarding card surfaces. |
| `Color.glassBackground` | `.white.opacity(0.6)` | Translucent info cards. |
| `Color.cardBackgroundLight` | `.white.opacity(0.85)` | Light mode card backing. |
| `Color.cardBackgroundDark` | `.black.opacity(0.15)` | Dark mode card backing. |
| `Color.codeBackground` | `.black.opacity(0.2)` | Inspector raw input block. |
| `Color.codeBackgroundDark` | `.black.opacity(0.3)` | Inspector JSON block. |

#### Shadows

| Token | Opacity | Use case |
|-------|---------|----------|
| `Color.shadowBase` | `black` | Base shadow color. |
| `Color.shadowVerySubtle` | `0.02` | Resting card shadow. |
| `Color.shadowSubtle` | `0.03` | Soft card shadows. |
| `Color.shadowLight` | `0.04` | Light mode card shadow. |
| `Color.shadowMedium` | `0.08` | Hover shadows. |
| `Color.shadowHeavy` | `0.25` | Dark mode card shadow. |

#### Gradients and Backgrounds

Gradients live in the `Gradients` namespace. Always use these for visual highlights, charts, and onboarding hero states.

- `Gradients.brand` — Accent color to royal purple. Used for onboarding and main buttons.
- `Gradients.success` — Vibrant green to custom mint. Used for daily activity and success states.
- `Gradients.warning` — Vivid orange to yellow. Used for cautions.
- `Gradients.negative` — Crimson red to deep rose. Used for deletion and errors.
- `Gradients.pending` — Semi-transparent gray gradient. Used for pending/loading states.
- `Gradients.logo` — Blue-to-purple-to-orange gradient. Used for the Uniks logo mark.
- `Gradients.hero` — Blue-to-purple gradient. Used for onboarding hero text.
- `Gradients.brandArea` — Accent-to-transparent gradient. Used for area charts.
- `Gradients.area(for:)` — Generates a color-specific area gradient for sparklines.
- `MeshBackground` — Multi-layered glow mesh using `Color.brandBlueGlowStrong`, `Color.brandPurpleGlowMedium`, and `Color.brandRedGlowSoft` on a neutral grouped background.

### Typography

Use `Font.u*` static properties only. All typography utilizes Apple's **rounded system font design** (`design: .rounded`) for visual excellence and scannability.

| Token | Style | Use case |
|-------|-------|----------|
| `Font.uTitle` | `.largeTitle.weight(.bold).rounded` | Onboarding titles. |
| `Font.uHeadline` | `.headline.weight(.semibold).rounded` | Card titles, button labels. |
| `Font.uBody` | `.body.rounded` | Primary content text. |
| `Font.uCallout` | `.subheadline.rounded` | Secondary body, empty-state text. |
| `Font.uFootnote` | `.footnote.rounded` | Minor labels. |
| `Font.uCaption` | `.caption.weight(.medium).rounded` | Chips, badges, metadata. |
| `Font.uCaption2` | `.caption2.rounded` | Axis labels, tiny labels. |
| `Font.uNumeric` | `.caption.monospacedDigit().rounded` | Numbers in charts. |
| `Font.uLargeIcon` | system 48 | Empty-state icons. |
| `Font.uExtraLargeIcon` | system 72 | Onboarding icons. |
| `Font.uHero` | system 38 bold rounded | Onboarding hero headlines. |
| `Font.uHeroSmall` | system 32 bold rounded | Onboarding sub-headlines. |
| `Font.uBrandTitle` | `.title.weight(.bold).rounded` | Onboarding card titles. |
| `Font.uBrandTitle2` | `.title2.rounded` | Icon labels, large status icons. |
| `Font.uBrandBodyBold` | `.body.weight(.bold).rounded` | Logo wordmark bold part. |
| `Font.uBrandBodyMedium` | `.body.weight(.medium).rounded` | Logo wordmark secondary part. |
| `Font.uMicro` | system 10 rounded | Fine print, legal hints. |
| `Font.uMicroBold` | system 10 semibold rounded | Sidebar status label. |
| `Font.uTiny` | system 9 rounded | Micro metadata. |
| `Font.uMonospacedTitle` | `.title3.monospaced` | Inspector ID badge. |
| `Font.uMonospacedBody` | `.body.monospaced` | Inspector JSON block. |
| `Font.uMonospacedCaption` | `.caption.monospaced` | Keyboard shortcut hints. |

### Icons

Use `Icons.*` constants only. No raw SF Symbol strings in views.

| Constant | Symbol | Use case |
|----------|--------|----------|
| `Icons.add` | `plus` | Toolbar add/log button. |
| `Icons.events` | `list.bullet` | Events tab. |
| `Icons.dashboard` | `chart.bar` | Dashboard tab. |
| `Icons.settings` | `gear` | Settings tab. |
| `Icons.success` | `checkmark.circle.fill` | Parsed state, downloaded model. |
| `Icons.failure` | `exclamationmark.circle.fill` | Failed state. |
| `Icons.pending` | `sparkles` | Pending/AI parsing state. |
| `Icons.emptyEvents` | `text.badge.plus` | Empty events list. |
| `Icons.emptyDashboard` | `chart.bar` | Empty dashboard. |
| `Icons.bolt` | `bolt.fill` | Onboarding capture speed. |
| `Icons.trash` | `trash` | Deletion actions. |
| `Icons.retry` | `arrow.clockwise` | Retry parsing button. |
| `Icons.engine` | `cpu` | AI engine settings. |
| `Icons.model` | `square.3.layers.3d` | Local model settings. |
| `Icons.privacy` | `lock.shield` | Privacy & About settings. |
| `Icons.sparkles` | `sparkles` | AI / logo mark. |
| `Icons.sparkle` | `sparkle` | Offline indicator. |
| `Icons.chevronLeft` | `chevron.left` | Navigation back button. |
| `Icons.pencil` | `pencil` | Edit action. |
| `Icons.plus` | `plus` | Add/new event. |
| `Icons.trayAndArrowDown` | `tray.and.arrow.down.fill` | Inbox. |
| `Icons.inspector` | `doc.text.magnifyingglass` | Empty inspector state. |


## Shared components

Most shared UI elements live in `uniks/UI/Shared/`, while settings-specific layout blocks reside in `uniks/UI/Settings/SettingsControls.swift`.

### `UniksLogoHeader`

Custom header containing the Uniks logo and a multicolor sparkles gradient indicator.

### `LocalModelRow`

An ML model status card providing dynamic feedback for model state (Downloaded, Downloading with linear indicator, Not Downloaded with download action).

### `UCard`

Reusable card container with title and content. Uses `.cardStyle()`.

```swift
UCard(title: "Category Totals") {
    // content
}
```

### `UChip`

Reusable chip for categories, values, and tags.

```swift
UChip(text: "Running", style: .category)
UChip(text: "5 km", style: .value)
UChip(text: "morning", style: .tag)
```

Styles:
- `.category` — accent background, accent foreground.
- `.value` — positive background, positive foreground.
- `.tag` — tertiary background, secondary foreground.
- `.neutral` — secondary background, secondary foreground.

### `UBadge`

Status badge for `HabitEventState`.

```swift
UBadge(state: .parsed)
```

### `UEmptyState`

Unified empty-state placeholder.

```swift
UEmptyState(
    icon: Icons.emptyEvents,
    title: "No events yet",
    message: "Tap + to log your first event."
)
```

### `UFlowLayout`

Horizontal flow layout for chips and tags.

```swift
UFlowLayout(spacing: .small) {
    UChip(text: "tag1", style: .tag)
    UChip(text: "tag2", style: .tag)
}
```

## View modifiers

Defined in `uniks/UI/DesignSystem/ViewModifiers.swift`.

- `.cardStyle()` — applies double-layer system material background (`.regularMaterial`), custom high-contrast borders, and soft drop shadows.
- `.chipStyle(background:foreground:)` — applies capsule background, caption font, and fine border stroke to tags/chips.
- `.interactiveScale()` — applies spring-based press scaling (scales down to 0.97 on click/press) for premium tactile feedback.
- `.premiumTextFieldStyle()` — applies rounded background shapes and delicate borders to text inputs.

## Spacing and sizing rules

Spacing and sizing are not arbitrary. Every margin, gap, and corner radius must come from the design system.

- **Padding:** Use `CGFloat.spacing(_:)` for every `.padding()` modifier. `spacing: 0` is allowed only when intentionally removing gaps.
- **Stack gaps:** Use `CGFloat.spacing(_:)` for every `spacing:` argument in `HStack`, `VStack`, `LazyVStack`, etc.
- **Corner radii:** Use `CGFloat.radius(_:)` for every `cornerRadius`. Use `Radius.pill` for chips, badges, and capsules.
- **Frame sizes:** Prefer shared constants or documented layout values. Hardcoded `.frame(width:height:)` is allowed only for one-off layouts (charts, onboarding hero art) and must be accompanied by a `// swiftlint:disable:next hardcoded_frame_size` comment explaining why a token cannot be used.
- **No magic numbers:** `4`, `6`, `8`, `12`, `16`, `20`, `24`, `32`, `48` all have tokens. Use them.

## Button guidelines

- **Tactile feedback:** Apply `.interactiveScale()` to every tappable custom button.
- **Primary actions:** Use `Gradients.brand` fills with `Color.onAccent` text, or the system `.borderedProminent` style.
- **Secondary actions:** Use `Color.accentSoft` background with `Color.accent` foreground.
- **Destructive actions:** Use `Color.negativeSubtle` background with `Color.negative` foreground.
- **Icon-only buttons:** Must include `.accessibilityLabel(...)`.
- **Loading states:** Replace button text with a `ProgressView()` and disable the button.

## Do and don't

### Do

```swift
Text("Hello")
    .font(.uBody)
    .foregroundStyle(Color.secondaryLabel)
    .padding(.spacing(.small))

UChip(text: "Running", style: .category)

Image(systemName: Icons.add)
```

### Don't

```swift
Text("Hello")
    .font(.system(size: 14))
    .foregroundStyle(.gray)
    .padding(8)

HStack(spacing: 6) {
    Image(systemName: "plus")
    Text("Log")
}

Text("Running")
    .padding(.horizontal, 8)
    .background(Color.blue.opacity(0.15), in: Capsule())

Image(systemName: "plus")
```

## Adding to the design system

1. Need a new token? Add it to the appropriate file in `uniks/UI/DesignSystem/`.
2. Need a new component? Add it to `uniks/UI/Shared/` and document it here.
3. Never add a one-off custom style in a view.
