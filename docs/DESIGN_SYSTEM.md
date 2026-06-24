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

#### Gradients and Backgrounds

Gradients live in the `Gradients` namespace. Always use these for visual highlights, charts, and onboarding hero states.

- `Gradients.brand` — Accent color to royal purple. Used for onboarding and main buttons.
- `Gradients.success` — Vibrant green to custom mint. Used for daily activity and success states.
- `Gradients.warning` — Vivid orange to yellow. Used for cautions.
- `Gradients.negative` — Crimson red to deep rose. Used for deletion and errors.
- `Gradients.pending` — Semi-transparent gray gradient. Used for pending/loading states.
- `MeshBackground` — Multi-layered glow mesh simulated using soft blurred colored circles (.blue, .purple, .red/pink) on a neutral backing, conforming to premium macOS styling guidelines.

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


## Shared components

Most shared UI elements live in `uniks/UI/Shared/`, while settings-specific layout blocks reside in `uniks/UI/Settings/SettingsControls.swift`.

### `UniksLogoHeader`

Custom header containing the Uniks logo and a multicolor sparkles gradient indicator.

### `SettingsDropdownPicker`

A standardized dropdown selection row that fits inside card groups and features clean borders.

### `SettingsToggleRow`

A switch control wrapper with custom titles, multi-line descriptions, and standard padding.

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

Defined in `uniks/UI/DesignSystem/ViewModifiers.swift` and `uniks/UI/EventList/EventEditView.swift`.

- `.cardStyle()` — applies double-layer system material background (`.regularMaterial`), custom high-contrast borders, and soft drop shadows.
- `.chipStyle(background:foreground:)` — applies capsule background, caption font, and fine border stroke to tags/chips.
- `.interactiveScale()` — applies spring-based press scaling (scales down to 0.97 on click/press) for premium tactile feedback.
- `.premiumTextFieldStyle()` — applies rounded background shapes and delicate borders to text inputs.


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

Text("Running")
    .padding(.horizontal, 8)
    .background(Color.blue.opacity(0.15), in: Capsule())

Image(systemName: "plus")
```

## Adding to the design system

1. Need a new token? Add it to the appropriate file in `uniks/UI/DesignSystem/`.
2. Need a new component? Add it to `uniks/UI/Shared/` and document it here.
3. Never add a one-off custom style in a view.
