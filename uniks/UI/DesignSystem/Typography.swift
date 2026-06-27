//
//  Typography.swift
//  uniks
//
//  Single source of truth for text styles.
//  Views must not call .system(size:) directly.
//

import SwiftUI

// This file is the canonical source of system(size:) font definitions; views must use Font.u* tokens.
// swiftlint:disable hardcoded_font_size

enum Typography {
    static let title = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let callout = Font.system(.subheadline, design: .rounded)
    static let footnote = Font.system(.footnote, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded).weight(.medium)
    static let caption2 = Font.system(.caption2, design: .rounded)
    static let numeric = Font.system(.caption, design: .rounded).monospacedDigit()
    static let input = Font.system(.title3, design: .rounded)

    static let largeIcon: Font = .system(size: 48, weight: .regular)
    static let extraLargeIcon: Font = .system(size: 72, weight: .regular)

    // MARK: - Marketing / Onboarding

    static let hero = Font.system(size: 38, weight: .bold, design: .rounded)
    static let heroSmall = Font.system(size: 32, weight: .bold, design: .rounded)
    static let brandTitle = Font.system(.title, design: .rounded).weight(.bold)
    static let brandTitle2 = Font.system(.title2, design: .rounded)
    static let brandBodyBold = Font.system(.body, design: .rounded).weight(.bold)
    static let brandBodyMedium = Font.system(.body, design: .rounded).weight(.medium)

    // MARK: - Small / Monospaced

    static let micro = Font.system(size: 10, design: .rounded)
    static let microBold = Font.system(size: 10, design: .rounded).weight(.semibold)
    static let tiny = Font.system(size: 9, design: .rounded)
    static let monospacedTitle = Font.system(.title3, design: .monospaced)
    static let monospacedBody = Font.system(.body, design: .monospaced)
    static let monospacedCaption = Font.system(.caption, design: .monospaced)
}

extension Font {
    static let uTitle = Typography.title
    static let uHeadline = Typography.headline
    static let uBody = Typography.body
    static let uCallout = Typography.callout
    static let uFootnote = Typography.footnote
    static let uCaption = Typography.caption
    static let uCaption2 = Typography.caption2
    static let uNumeric = Typography.numeric
    static let uInput = Typography.input
    static let uLargeIcon = Typography.largeIcon
    static let uExtraLargeIcon = Typography.extraLargeIcon
    static let uHero = Typography.hero
    static let uHeroSmall = Typography.heroSmall
    static let uBrandTitle = Typography.brandTitle
    static let uBrandTitle2 = Typography.brandTitle2
    static let uBrandBodyBold = Typography.brandBodyBold
    static let uBrandBodyMedium = Typography.brandBodyMedium
    static let uMicro = Typography.micro
    static let uMicroBold = Typography.microBold
    static let uTiny = Typography.tiny
    static let uMonospacedTitle = Typography.monospacedTitle
    static let uMonospacedBody = Typography.monospacedBody
    static let uMonospacedCaption = Typography.monospacedCaption
}

// swiftlint:enable hardcoded_font_size
