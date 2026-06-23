//
//  QuickInputView.swift
//  uniks
//
//  Shared input bar for quickly logging events.
//

import SwiftUI

struct QuickInputView: View {
    @State private var viewModel: QuickInputViewModel

    init(viewModel: QuickInputViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 12) {
            TextField("Log something...", text: $viewModel.text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .lineLimit(1...3)
                .onSubmit {
                    Task { await viewModel.submit() }
                }

            HStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Spacer()
                Button("Save") {
                    Task { await viewModel.submit() }
                }
                .disabled(viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
            }
        }
        .padding()
        .frame(minWidth: 320, idealWidth: 400, maxWidth: 500)
    }
}
