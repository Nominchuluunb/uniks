//
//  QuickInputView.swift
//  uniks
//
//  Whisper Flow-inspired input bar with engine status and inline parse preview.
//

import SwiftUI

struct QuickInputView: View {
    @State private var viewModel: QuickInputViewModel
    @FocusState private var isFocused: Bool

    init(viewModel: QuickInputViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Engine status badge
            HStack {
                UEngineStatusBadge(
                    modelName: viewModel.activeModelName,
                    status: viewModel.engineStatus
                )
                Spacer()
            }
            .padding(.bottom, .spacing(.xSmall))

            // Input row
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
            .onAppear { isFocused = true }
            #if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                isFocused = true
            }
            #endif

            // Inline parsed preview (appears after successful save)
            if let preview = viewModel.lastParsedPreview {
                Divider()
                    .padding(.vertical, .spacing(.xxSmall))
                HStack(spacing: .spacing(.xSmall)) {
                    Image(systemName: Icons.success)
                        .font(.uCaption)
                        .foregroundStyle(Color.positive)
                    if let category = preview.category {
                        UChip(text: category, style: .category)
                    }
                    if let value = preview.value, let unit = preview.unit {
                        UChip(text: "\(value) \(unit)", style: .value)
                    }
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Divider()
                .padding(.vertical, .spacing(.xSmall))

            // Footer
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
                            .frame(
                                width: .sizing(.saveButtonProgressWidth),
                                height: .sizing(.saveButtonProgressHeight)
                            )
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
