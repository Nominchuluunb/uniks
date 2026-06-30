//
//  HapticEngine.swift
//  uniks
//
//  Centralized haptic feedback patterns for iOS.
//  Compile-guarded for iOS only — no-op on macOS.
//

import Foundation
#if os(iOS)
import UIKit
#endif

/// Centralized haptic feedback utility.
/// Provides typed haptic patterns that can be called from any view.
/// On macOS, all methods are no-ops.
@MainActor
enum HapticEngine {

    /// Light impact for subtle interactions (tap, toggle).
    static func light() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    /// Medium impact for confirmed actions (save, select).
    static func medium() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    /// Heavy impact for significant actions (delete, complete).
    static func heavy() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        #endif
    }

    /// Success notification (event saved, goal completed).
    static func success() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    /// Error notification (save failed, parse error).
    static func error() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
    }

    /// Warning notification (low confidence, review needed).
    static func warning() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }

    /// Selection changed (scrolling through items, picker change).
    static func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
}
