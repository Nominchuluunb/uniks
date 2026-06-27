//
//  USectionHeader.swift
//  uniks
//
//  Reusable icon + title section header.
//

import SwiftUI

struct USectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: .spacing(.xSmall)) {
            Image(systemName: icon)
            Text(title)
        }
    }
}

#Preview {
    USectionHeader(icon: Icons.engine, title: "AI Engine")
}
