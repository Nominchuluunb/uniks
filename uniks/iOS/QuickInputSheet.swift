//
//  QuickInputSheet.swift
//  uniks
//
//  iOS sheet wrapper for the QuickInput HUD.
//

import SwiftUI

#if os(iOS)
struct QuickInputSheet: View {
    let viewModel: QuickInputViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            QuickInputView(viewModel: viewModel)
                .navigationTitle("New Log")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .presentationDetents([.height(220), .medium])
        .presentationDragIndicator(.visible)
    }
}
#endif
