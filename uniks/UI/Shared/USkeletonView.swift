//
//  USkeletonView.swift
//  uniks
//
//  Shimmer skeleton loaders for loading states.
//  Matches the layout of real content for visual stability.
//

import SwiftUI

// MARK: - Shimmer Modifier

/// Applies a shimmer animation overlay to create a loading placeholder effect.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if !reduceMotion {
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.6)
                        .offset(x: phase * geo.size.width)
                        .onAppear {
                            withAnimation(
                                .linear(duration: 1.5)
                                .repeatForever(autoreverses: false)
                            ) {
                                phase = 1.5
                            }
                        }
                    }
                }
                .clipped()
            )
    }
}

extension View {
    /// Applies a shimmer skeleton loading effect.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Primitives

/// A rounded rectangle placeholder block.
struct SkeletonBlock: View {
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 14) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: .radius(.small))
            .fill(Color.tertiaryGroupedBackground)
            .frame(width: width, height: height)
            .shimmer()
    }
}

/// A circle placeholder (for avatars/icons).
struct SkeletonCircle: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.tertiaryGroupedBackground)
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - USkeletonRow (matches EventRowCard layout)

/// Skeleton placeholder that matches the EventRowCard layout.
struct USkeletonRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: .spacing(.medium)) {
            VStack(alignment: .leading, spacing: .spacing(.small)) {
                SkeletonBlock(width: 200, height: 16)
                HStack(spacing: .spacing(.xSmall)) {
                    SkeletonBlock(width: 60, height: 12)
                    SkeletonBlock(width: 40, height: 12)
                    SkeletonBlock(width: 50, height: 12)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: .spacing(.small)) {
                SkeletonBlock(width: 50, height: 12)
                SkeletonBlock(width: 35, height: 12)
            }
        }
        .cardStyle()
    }
}

// MARK: - USkeletonCard (matches UCard layout)

/// Skeleton placeholder that matches the UCard layout.
struct USkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            SkeletonBlock(width: 120, height: 16)

            VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                SkeletonBlock(height: 14)
                SkeletonBlock(width: 180, height: 14)
            }

            HStack(spacing: .spacing(.small)) {
                SkeletonBlock(width: 80, height: 60)
                SkeletonBlock(width: 80, height: 60)
                SkeletonBlock(width: 80, height: 60)
            }
        }
        .cardStyle()
    }
}

// MARK: - USkeletonStatRow (matches dashboard stat boxes)

/// Skeleton placeholder for the hero stat row.
struct USkeletonStatRow: View {
    var body: some View {
        HStack(spacing: .spacing(.small)) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: .spacing(.xSmall)) {
                    SkeletonCircle(size: 24)
                    SkeletonBlock(width: 50, height: 20)
                    SkeletonBlock(width: 70, height: 12)
                }
                .frame(maxWidth: .infinity)
                .cardStyle()
            }
        }
    }
}

// MARK: - Dashboard Skeleton

/// Full dashboard skeleton with stat row and cards.
struct UDashboardSkeleton: View {
    var body: some View {
        VStack(spacing: .spacing(.large)) {
            USkeletonStatRow()
            USkeletonCard()
            USkeletonCard()
            USkeletonCard()
        }
        .padding(.horizontal, .spacing(.medium))
    }
}

// MARK: - Event List Skeleton

/// Skeleton for the event list loading state.
struct UEventListSkeleton: View {
    var body: some View {
        VStack(spacing: .spacing(.xSmall)) {
            ForEach(0..<5, id: \.self) { index in
                USkeletonRow()
                    .staggeredAppear(index: index)
            }
        }
        .padding(.horizontal, .spacing(.medium))
    }
}

#Preview("Skeleton Row") {
    USkeletonRow()
        .padding()
}

#Preview("Skeleton Card") {
    USkeletonCard()
        .padding()
}

#Preview("Dashboard Skeleton") {
    UDashboardSkeleton()
        .padding()
}
