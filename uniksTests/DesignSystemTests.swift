//
//  DesignSystemTests.swift
//  uniks
//
//  Sanity tests for design-system tokens and shared components.
//

import SwiftUI
import XCTest
@testable import uniks

final class DesignSystemTests: XCTestCase {
    func testSpacingTokensArePositive() {
        XCTAssertGreaterThan(CGFloat.spacing(.xxxSmall), 0)
        XCTAssertGreaterThan(CGFloat.spacing(.xxSmall), 0)
        XCTAssertGreaterThan(CGFloat.spacing(.xSmall), 0)
        XCTAssertGreaterThan(CGFloat.spacing(.small), 0)
        XCTAssertGreaterThan(CGFloat.spacing(.medium), 0)
        XCTAssertGreaterThan(CGFloat.spacing(.large), 0)
        XCTAssertGreaterThan(CGFloat.spacing(.xLarge), 0)
        XCTAssertGreaterThan(CGFloat.spacing(.xxLarge), 0)
        XCTAssertGreaterThan(CGFloat.spacing(.xxxLarge), 0)
    }

    func testRadiusTokensArePositive() {
        XCTAssertGreaterThan(CGFloat.radius(.small), 0)
        XCTAssertGreaterThan(CGFloat.radius(.medium), 0)
        XCTAssertGreaterThan(CGFloat.radius(.large), 0)
        XCTAssertGreaterThan(Radius.pill, 0)
    }

    func testIconNamesAreNonEmpty() {
        XCTAssertFalse(Icons.add.isEmpty)
        XCTAssertFalse(Icons.events.isEmpty)
        XCTAssertFalse(Icons.dashboard.isEmpty)
        XCTAssertFalse(Icons.settings.isEmpty)
        XCTAssertFalse(Icons.success.isEmpty)
        XCTAssertFalse(Icons.failure.isEmpty)
    }

    func testTypographyStylesExist() {
        XCTAssertNotEqual(Font.uTitle, Font.uBody)
        XCTAssertNotEqual(Font.uHeadline, Font.uCaption)
    }
}
