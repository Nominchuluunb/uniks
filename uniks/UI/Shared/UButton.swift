//
//  UButton.swift
//  uniks
//
//  Reusable button with primary, secondary, destructive, and loading variants.
//

import SwiftUI

struct UButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
    }

    let title: String
    let style: Style
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(foregroundStyle)
                } else {
                    Text(title)
                        .font(.uHeadline)
                }
            }
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, .spacing(.xLarge))
            .padding(.vertical, .spacing(.small))
            .background(backgroundShape, in: Capsule())
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .interactiveScale()
        .accessibilityLabel(title)
    }

    private var backgroundShape: AnyShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(Gradients.brand)
        case .secondary:
            return AnyShapeStyle(Color.accentSoft)
        case .destructive:
            return AnyShapeStyle(Color.negativeSubtle)
        }
    }

    private var foregroundStyle: Color {
        switch style {
        case .primary:
            return Color.onAccent
        case .secondary:
            return Color.accent
        case .destructive:
            return Color.negative
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return Color.brandBlueShadowSoft
        case .secondary, .destructive:
            return Color.shadowVerySubtle
        }
    }
}

#Preview {
    VStack(spacing: .spacing(.medium)) {
        UButton("Download", style: .primary) {}
        UButton("Cancel", style: .secondary) {}
        UButton("Delete", style: .destructive) {}
        UButton("Loading", style: .primary, isLoading: true) {}
    }
    .padding()
}
