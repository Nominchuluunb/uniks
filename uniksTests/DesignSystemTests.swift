//
//  DesignSystemTests.swift
//  uniks
//
//  Sanity tests for design-system tokens and shared components.
//

import SwiftUI
import Testing
@testable import uniks

struct DesignSystemTests {

    @Test func spacingTokensArePositive() {
        #expect(CGFloat.spacing(.xxxSmall) > 0)
        #expect(CGFloat.spacing(.xxSmall) > 0)
        #expect(CGFloat.spacing(.xSmall) > 0)
        #expect(CGFloat.spacing(.small) > 0)
        #expect(CGFloat.spacing(.medium) > 0)
        #expect(CGFloat.spacing(.large) > 0)
        #expect(CGFloat.spacing(.xLarge) > 0)
        #expect(CGFloat.spacing(.xxLarge) > 0)
        #expect(CGFloat.spacing(.xxxLarge) > 0)
    }

    @Test func radiusTokensArePositive() {
        #expect(CGFloat.radius(.small) > 0)
        #expect(CGFloat.radius(.medium) > 0)
        #expect(CGFloat.radius(.large) > 0)
        #expect(Radius.pill > 0)
    }

    @Test func iconNamesAreNonEmpty() {
        #expect(!Icons.add.isEmpty)
        #expect(!Icons.events.isEmpty)
        #expect(!Icons.dashboard.isEmpty)
        #expect(!Icons.settings.isEmpty)
        #expect(!Icons.success.isEmpty)
        #expect(!Icons.failure.isEmpty)
    }

    @Test func typographyStylesExist() {
        #expect(Font.uTitle != Font.uBody)
        #expect(Font.uHeadline != Font.uCaption)
    }
}
