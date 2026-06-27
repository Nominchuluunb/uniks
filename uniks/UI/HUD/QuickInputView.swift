//
//  QuickInputView.swift
//  uniks
//
//  Whisper Flow-inspired input bar with smart suggestions and success animation.
//

import SwiftUI

struct QuickInputView: View {
    @State private var viewModel: QuickInputViewModel
    @FocusState private var isFocused: Bool
    @State private var showSuccess = false
    @State private var shake = false

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

            // Smart suggestion chips (recent categories)
            if viewModel.text.isEmpty, !viewModel.recentCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacing(.xSmall)) {
                        ForEach(viewModel.recentCategories, id: \.self) { category in
                            Button {
                                viewModel.text = category + " "
                                isFocused = true
                            } label: {
                                UChip(text: category, style: .category)
                            }
                            .buttonStyle(.plain)
                            .interactiveScale()
                        }
                    }
                }
                .padding(.bottom, .spacing(.xSmall))
            }

            // Quick-log templates
            if viewModel.text.isEmpty, !viewModel.templates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacing(.xSmall)) {
                        ForEach(viewModel.templates) { template in
                            Button {
                                viewModel.text = template.phrase
                                Task { await submit() }
                            } label: {
                                HStack(spacing: .spacing(.xxxSmall)) {
                                    Text(template.emoji)
                                    Text(template.phrase)
                                        .font(.uCaption)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, .spacing(.xSmall))
                                .padding(.vertical, .spacing(.xxSmall))
                                .background(Color.accentSubtle, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .interactiveScale()
                        }
                    }
                }
                .padding(.bottom, .spacing(.xSmall))
            }

            // Input row
            HStack(alignment: .top, spacing: .spacing(.small)) {
                ZStack {
                    Image(systemName: Icons.sparkle)
                        .font(.uInput)
                        .foregroundStyle(Gradients.brand)
                        .symbolEffect(.pulse, options: .repeating, value: viewModel.isSaving)
                        .opacity(showSuccess ? 0 : 1)

                    Image(systemName: Icons.success)
                        .font(.uInput)
                        .foregroundStyle(Color.positive)
                        .scaleEffect(showSuccess ? 1.2 : 0.5)
                        .opacity(showSuccess ? 1 : 0)
                }
                .padding(.top, .spacing(.small))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showSuccess)

                TextField("What did you do? (e.g. Ran 5km in 30m)", text: $viewModel.text, axis: .vertical)
                    .font(.uInput)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .padding(.vertical, .spacing(.small))
                    .focused($isFocused)
                    .onSubmit {
                        #if os(macOS)
                        Task { await submit() }
                        #endif
                    }
            }
            .offset(x: shake ? -6 : 0)
            .animation(shake ? .default.repeatCount(3, autoreverses: true).speed(6) : .default, value: shake)
            .onAppear { isFocused = true }
            #if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                isFocused = true
            }
            #endif

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
                    Task { await submit() }
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
                            .foregroundStyle(Color.onAccent)
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

    private func submit() async {
        await viewModel.submit()
        if viewModel.errorMessage != nil {
            shake = true
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                shake = false
            }
        } else {
            showSuccess = true
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                showSuccess = false
            }
        }
    }
}
