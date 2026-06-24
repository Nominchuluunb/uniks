//
//  Typography.swift
//  uniks
//
//  Single source of truth for text styles.
//  Views must not call .system(size:) directly.
//

import SwiftUI

enum Typography {
    static let title = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let callout = Font.system(.subheadline, design: .rounded)
    static let footnote = Font.system(.footnote, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded).weight(.medium)
    static let caption2 = Font.system(.caption2, design: .rounded)
    static let numeric = Font.system(.caption, design: .rounded).monospacedDigit()

    static let largeIcon: Font = .system(size: 48, weight: .regular)
    static let extraLargeIcon: Font = .system(size: 72, weight: .regular)
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
    static let uLargeIcon = Typography.largeIcon
    static let uExtraLargeIcon = Typography.extraLargeIcon
}
