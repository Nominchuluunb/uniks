//
//  UToast.swift
//  uniks
//
//  Floating toast/snackbar view for action feedback.
//

import SwiftUI

/// Floating toast notification view. Slides in from bottom on iOS, top-right on macOS.
struct UToast: View {
    let toast: ToastItem
    let onDismiss: () -> Void
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: .spacing(.small)) {
            Image(systemName: toast.type.icon)
                .font(.uCaption)
                .foregroundStyle(toast.type.color)

            Text(toast.message)
                .font(.uCallout)
                .foregroundStyle(Color.primaryLabel)
                .lineLimit(2)

            Spacer()

            if let actionLabel = toast.actionLabel {
                Button {
                    onAction()
                } label: {
                    Text(actionLabel)
                        .font(.uCaption)
                        .fontWeight(.bold)
                        .foregroundStyle(toast.type.color)
                        .padding(.horizontal, .spacing(.small))
                        .padding(.vertical, .spacing(.xxSmall))
                        .background(
                            toast.type.color.opacity(0.12),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .interactiveScale()
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.uCaption2)
                    .foregroundStyle(Color.secondaryLabel)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss notification")
        }
        .padding(.spacing(.medium))
        .background(
            RoundedRectangle(cornerRadius: .radius(.medium))
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .radius(.medium))
                .stroke(toast.type.color.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: Color.shadowMedium, radius: 12, x: 0, y: 4)
        .padding(.horizontal, .spacing(.medium))
    }
}

/// Overlay modifier that shows the current toast from ToastManager.
struct ToastOverlay: ViewModifier {
    @Environment(ToastManager.self) private var toastManager

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = toastManager.currentToast {
                    UToast(
                        toast: toast,
                        onDismiss: { toastManager.dismiss() },
                        onAction: {
                            Task {
                                await toast.action?()
                                toastManager.dismiss()
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, .spacing(.xxLarge))
                }
            }
            .animation(AnimationTokens.spring, value: toastManager.currentToast?.id)
    }
}

extension View {
    /// Adds the toast overlay to this view.
    func toastOverlay() -> some View {
        modifier(ToastOverlay())
    }
}

#Preview {
    VStack {
        Spacer()
        UToast(
            toast: ToastItem(message: "Event deleted", type: .undo, actionLabel: "Undo"),
            onDismiss: {},
            onAction: {}
        )
    }
    .padding()
}
