//
//  UProgressBar.swift
//  uniks
//
//  Determinate progress bar using design system tokens.
//

import SwiftUI

struct UProgressBar: View {
    let progress: Double
    var tint: Color = .brandBlue

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: .radius(.small))
                    .fill(Color.tertiaryGroupedBackground)

                RoundedRectangle(cornerRadius: .radius(.small))
                    .fill(tint)
                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: .sizing(.progressBarHeight))
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

#Preview {
    VStack(spacing: .spacing(.medium)) {
        UProgressBar(progress: 0.0)
        UProgressBar(progress: 0.45)
        UProgressBar(progress: 1.0, tint: .positive)
    }
    .padding()
}
