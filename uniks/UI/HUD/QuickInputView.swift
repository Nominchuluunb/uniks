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
                Image(systemName: "sparkle")
                    .font(.title3)
                    .foregroundStyle(Gradients.brand)
                    .padding(.top, .spacing(.small) + 1)
                    .symbolEffect(.pulse, options: .repeating, value: viewModel.isSaving)

                TextField("What did you do? (e.g. Ran 5km in 30m)", text: $viewModel.text, axis: .vertical)
                    .font(.system(.title3, design: .rounded))
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
                .background(Color.separator.opacity(0.3))
                .padding(.vertical, .spacing(.xSmall))

            HStack {
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 4) {
                        Image(systemName: Icons.failure)
                        Text(errorMessage)
                    }
                    .font(.uCaption)
                    .foregroundStyle(Color.negative)
                } else {
                    #if os(macOS)
                    Text("Press ↵ to save • Esc to dismiss")
                        .font(.uCaption2)
                        .foregroundStyle(Color.secondaryLabel.opacity(0.7))
                    #else
                    Text("Type naturally to capture details")
                        .font(.uCaption2)
                        .foregroundStyle(Color.secondaryLabel.opacity(0.7))
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
                            .foregroundStyle(.white)
                            .padding(.horizontal, .spacing(.medium))
                            .padding(.vertical, .spacing(.xxSmall))
                            .background(Gradients.brand, in: Capsule())
                            .shadow(color: Color.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
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
