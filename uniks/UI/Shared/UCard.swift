//
//  UCard.swift
//  uniks
//
//  Reusable card container with title and content.
//

import SwiftUI

struct UCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            Text(title)
                .font(.uHeadline)

            content
        }
        .cardStyle()
    }
}

#Preview {
    UCard(title: "Preview") {
        Text("Card content")
    }
    .padding()
}
