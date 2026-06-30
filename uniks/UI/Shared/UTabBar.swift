//
//  UTabBar.swift
//  uniks
//
//  Custom floating tab bar for iOS with elevated FAB center button.
//

import SwiftUI

#if os(iOS)

/// Tab items for the iOS floating tab bar.
enum UTabItem: Int, CaseIterable {
    case events
    case dashboard
    case log
    case settings

    var icon: String {
        switch self {
        case .events: return Icons.events
        case .dashboard: return Icons.dashboard
        case .log: return Icons.add
        case .settings: return Icons.settings
        }
    }

    var label: String {
        switch self {
        case .events: return "Events"
        case .dashboard: return "Dashboard"
        case .log: return "Log"
        case .settings: return "Settings"
        }
    }
}

/// A floating capsule-shaped tab bar with an elevated center FAB button.
struct UTabBar: View {
    @Binding var selectedTab: UTabItem
    let onLogTapped: () -> Void

    @State private var isVisible = true

    var body: some View {
        HStack(spacing: 0) {
            ForEach(UTabItem.allCases, id: \.rawValue) { tab in
                if tab == .log {
                    // Elevated center FAB
                    fabButton
                } else {
                    tabButton(for: tab)
                }
            }
        }
        .padding(.horizontal, .spacing(.medium))
        .padding(.vertical, .spacing(.xSmall))
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(Color.separatorVeryFaint, lineWidth: 0.5)
        )
        .shadow(color: Color.shadowMedium, radius: 16, x: 0, y: 8)
        .padding(.horizontal, .spacing(.large))
        .padding(.bottom, .spacing(.xSmall))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 80)
        .animation(AnimationTokens.spring, value: isVisible)
    }

    private func tabButton(for tab: UTabItem) -> some View {
        Button {
            HapticEngine.selection()
            withAnimation(AnimationTokens.fast) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: .spacing(.xxxSmall)) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tab ? Color.accent : Color.secondaryLabel)
                    .symbolEffect(.bounce, value: selectedTab == tab)

                Text(tab.label)
                    .font(.uTiny)
                    .foregroundStyle(selectedTab == tab ? Color.accent : Color.secondaryLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacing(.xxSmall))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    private var fabButton: some View {
        Button {
            HapticEngine.medium()
            onLogTapped()
        } label: {
            ZStack {
                Circle()
                    .fill(Gradients.brand)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.brandBlueShadow, radius: 8, x: 0, y: 4)

                Image(systemName: Icons.add)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.onAccent)
            }
            .offset(y: -12)
        }
        .buttonStyle(.plain)
        .interactiveScale()
        .accessibilityLabel("Log new event")
        .frame(maxWidth: .infinity)
    }

    /// Call this to show/hide the tab bar (e.g., on scroll).
    func setVisible(_ visible: Bool) -> UTabBar {
        var copy = self
        copy._isVisible = State(initialValue: visible)
        return copy
    }
}

/// Modifier that hides the tab bar when scrolling down.
struct HideOnScrollModifier: ViewModifier {
    @Binding var isTabBarVisible: Bool

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        let delta = value.translation.height
                        if delta < -20 {
                            withAnimation(AnimationTokens.fast) {
                                isTabBarVisible = false
                            }
                        } else if delta > 20 {
                            withAnimation(AnimationTokens.fast) {
                                isTabBarVisible = true
                            }
                        }
                    }
            )
    }
}

extension View {
    /// Hides a bound tab bar visibility state when scrolling down.
    func hideTabBarOnScroll(_ isVisible: Binding<Bool>) -> some View {
        modifier(HideOnScrollModifier(isTabBarVisible: isVisible))
    }
}

#Preview {
    struct Preview: View {
        @State var selected = UTabItem.events
        var body: some View {
            VStack {
                Spacer()
                UTabBar(selectedTab: $selected, onLogTapped: {})
            }
        }
    }
    return Preview()
}

#endif
