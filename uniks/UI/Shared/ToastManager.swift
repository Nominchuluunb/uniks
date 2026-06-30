//
//  ToastManager.swift
//  uniks
//
//  Observable toast/snackbar manager for in-app action feedback.
//

import SwiftUI

/// Describes a single toast notification.
struct ToastItem: Identifiable, Sendable {
    let id = UUID()
    let message: String
    let type: ToastType
    let actionLabel: String?
    let action: (@Sendable @MainActor () async -> Void)?
    let duration: TimeInterval

    enum ToastType: Sendable {
        case success
        case error
        case undo
        case info

        var icon: String {
            switch self {
            case .success: return Icons.success
            case .error: return Icons.failure
            case .undo: return Icons.retry
            case .info: return Icons.pending
            }
        }

        var color: Color {
            switch self {
            case .success: return Color.positive
            case .error: return Color.negative
            case .undo: return Color.accent
            case .info: return Color.secondaryLabel
            }
        }
    }

    init(
        message: String,
        type: ToastType,
        actionLabel: String? = nil,
        action: (@Sendable @MainActor () async -> Void)? = nil,
        duration: TimeInterval = 4.0
    ) {
        self.message = message
        self.type = type
        self.actionLabel = actionLabel
        self.action = action
        self.duration = duration
    }
}

/// Manages the toast queue and auto-dismissal.
@MainActor
@Observable
final class ToastManager {
    private(set) var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?

    /// Shows a toast, replacing any current one.
    func show(
        _ message: String,
        type: ToastItem.ToastType = .info,
        actionLabel: String? = nil,
        action: (@Sendable @MainActor () async -> Void)? = nil,
        duration: TimeInterval = 4.0
    ) {
        dismissTask?.cancel()

        let toast = ToastItem(
            message: message,
            type: type,
            actionLabel: actionLabel,
            action: action,
            duration: duration
        )

        withAnimation(AnimationTokens.spring) {
            currentToast = toast
        }

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    /// Shows a success toast.
    func success(_ message: String) {
        show(message, type: .success)
    }

    /// Shows an error toast.
    func error(_ message: String, retryAction: (@Sendable @MainActor () async -> Void)? = nil) {
        show(message, type: .error, actionLabel: retryAction != nil ? "Retry" : nil, action: retryAction)
    }

    /// Shows an undo toast with 5-second timeout.
    func showUndo(_ message: String, undoAction: @escaping @Sendable @MainActor () async -> Void) {
        show(message, type: .undo, actionLabel: "Undo", action: undoAction, duration: 5.0)
    }

    /// Dismisses the current toast.
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(AnimationTokens.fast) {
            currentToast = nil
        }
    }
}
