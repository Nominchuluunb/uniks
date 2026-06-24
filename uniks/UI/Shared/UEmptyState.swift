//
//  UEmptyState.swift
//  uniks
//
//  Shared empty-state placeholder.
//

import SwiftUI

struct UEmptyState: View {
    let icon: String
    let title: String
    let message: String
    @State private var animate = false

    var body: some View {
        VStack(spacing: .spacing(.medium)) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Gradients.brand)
                .shadow(color: Color.accentColor.opacity(0.2), radius: 10, x: 0, y: 4)
                .scaleEffect(animate ? 1.0 : 0.85)
                .opacity(animate ? 1.0 : 0.0)

            Text(title)
                .font(.uHeadline)
                .opacity(animate ? 1.0 : 0.0)

            Text(message)
                .font(.uCallout)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacing(.large))
                .opacity(animate ? 0.8 : 0.0)
        }
        .padding(.spacing(.medium))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                animate = true
            }
        }
    }
}

#Preview {
    UEmptyState(
        icon: Icons.emptyEvents,
        title: "No events yet",
        message: "Tap + to log your first event."
    )
}
