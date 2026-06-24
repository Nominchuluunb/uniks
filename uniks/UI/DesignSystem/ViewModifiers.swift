//
//  ViewModifiers.swift
//  uniks
//
//  Reusable view modifiers that apply design-system tokens.
//

import SwiftUI

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(.spacing(.medium))
            .background(
                RoundedRectangle(cornerRadius: .radius(.medium))
                    .fill(colorScheme == .dark ? Color.black.opacity(0.15) : Color.white.opacity(0.85))
            )
            .background(
                RoundedRectangle(cornerRadius: .radius(.medium))
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .radius(.medium))
                    .stroke(Color.separator.opacity(colorScheme == .dark ? 0.4 : 0.6), lineWidth: 0.5)
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.04),
                radius: colorScheme == .dark ? 12 : 8,
                x: 0,
                y: colorScheme == .dark ? 6 : 4
            )
    }
}

struct ChipStyle: ViewModifier {
    let background: Color
    let foreground: Color

    func body(content: Content) -> some View {
        content
            .font(.uCaption)
            .foregroundStyle(foreground)
            .padding(.horizontal, .spacing(.xSmall))
            .padding(.vertical, .spacing(.xxSmall))
            .background(
                Capsule()
                    .fill(background)
            )
            .overlay(
                Capsule()
                    .stroke(foreground.opacity(0.12), lineWidth: 0.5)
            )
    }
}

struct InteractiveScale: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func chipStyle(background: Color, foreground: Color) -> some View {
        modifier(ChipStyle(background: background, foreground: foreground))
    }

    func interactiveScale() -> some View {
        modifier(InteractiveScale())
    }
}
