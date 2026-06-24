//
//  QuickInputView.swift
//  uniks
//
//  Shared input bar for quickly logging events.
//

import SwiftUI

struct QuickInputView: View {
    @State private var viewModel: QuickInputViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    init(viewModel: QuickInputViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: .spacing(.small)) {
                Image(systemName: Icons.sparkle)
                    .font(.uInput)
                    .foregroundStyle(Gradients.brand)
                    .padding(.top, .spacing(.small))
                    .symbolEffect(.pulse, options: .repeating, value: viewModel.isSaving)

                TextField("What did you do? (e.g. Ran 5km in 30m)", text: $viewModel.text, axis: .vertical)
                    .font(.uInput)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .padding(.vertical, .spacing(.small))
                    .focused($isFocused)
                    .onSubmit {
                        #if os(macOS)
                        Task { await viewModel.submit() }
                        #endif
                    }
            }
            .onAppear {
                isFocused = true
            }
            #if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                isFocused = true
            }
            #endif

            Divider()
                .padding(.vertical, .spacing(.xSmall))

            HStack {
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: .spacing(.xxSmall)) {
                        Image(systemName: Icons.failure)
                        Text(errorMessage)
                    }
                    .font(.uCaption)
                    .foregroundStyle(Color.negative)
                } else {
                    #if os(macOS)
                    Text("Press ↵ to save • Esc to dismiss")
                        .font(.uCaption2)
                        .foregroundStyle(Color.secondaryLabel)
                    #else
                    Text("Type naturally to capture details")
                        .font(.uCaption2)
                        .foregroundStyle(Color.secondaryLabel)
                    #endif
                }

                Spacer()

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 44, height: 20)
                    } else {
                        Text("Save")
                            .font(.uCaption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primaryLabel)
                            .padding(.horizontal, .spacing(.medium))
                            .padding(.vertical, .spacing(.xxSmall))
                            .background(Gradients.brand, in: Capsule())
                    }
                }
                .buttonStyle(.plain)
                .interactiveScale()
                .disabled(viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
            }
        }
        .padding(.spacing(.medium))
        .frame(minWidth: 320, idealWidth: 420, maxWidth: 500)
    }
}
