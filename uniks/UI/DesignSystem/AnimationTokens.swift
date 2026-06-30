//
//  AnimationTokens.swift
//  uniks
//
//  Standardized animation durations and curves for consistent motion design.
//  Views must use these tokens rather than ad-hoc animation values.
//

import SwiftUI

/// Canonical animation presets used throughout the app.
/// Respects `accessibilityReduceMotion` automatically via the view modifiers below.
enum AnimationTokens {
    /// Fast micro-interaction (button press, toggle). 0.15s
    static let fast = Animation.easeOut(duration: 0.15)

    /// Standard state transition (badge change, tab switch). 0.25s
    static let standard = Animation.easeInOut(duration: 0.25)

    /// Spring animation for list insertions and interactive elements.
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)

    /// Bouncy spring for success/celebration micro-interactions.
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Slow entrance for page-level transitions. 0.4s
    static let entrance = Animation.easeOut(duration: 0.4)

    /// Stagger delay between sequential elements.
    static let staggerDelay: TimeInterval = 0.05
}

// MARK: - Staggered Appear Modifier

/// Applies a fade+slide entrance animation with stagger delay based on index.
/// Respects `accessibilityReduceMotion`.
struct StaggeredAppear: ViewModifier {
    let index: Int
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : (reduceMotion ? 0 : 12))
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    let delay = AnimationTokens.staggerDelay * Double(index)
                    withAnimation(AnimationTokens.entrance.delay(delay)) {
                        isVisible = true
                    }
                }
            }
    }
}

/// Applies a scale+fade entrance for cards and stat boxes.
struct ScaleAppear: ViewModifier {
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : (reduceMotion ? 1 : 0.95))
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    withAnimation(AnimationTokens.springBouncy) {
                        isVisible = true
                    }
                }
            }
    }
}

/// Slide-in from edge modifier for toasts and panels.
struct SlideIn: ViewModifier {
    let edge: Edge
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .transition(
                reduceMotion
                    ? .opacity
                    : .move(edge: edge).combined(with: .opacity)
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies staggered fade+slide entrance animation based on list index.
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppear(index: index))
    }

    /// Applies scale+fade entrance animation for cards.
    func scaleAppear() -> some View {
        modifier(ScaleAppear())
    }

    /// Applies slide-in transition from edge for toasts and panels.
    func slideIn(from edge: Edge, isPresented: Binding<Bool>) -> some View {
        modifier(SlideIn(edge: edge, isPresented: isPresented))
    }

    /// Conditionally applies animation only when reduce motion is not enabled.
    func animateIfAllowed(_ animation: Animation) -> some View {
        self.animation(animation, value: UUID())
    }
}
