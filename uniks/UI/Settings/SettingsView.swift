//
//  SettingsView.swift
//  uniks
//
//  User settings for engine selection, local model downloads, and app info.
//

import SwiftUI

@MainActor
enum SettingsTab: Hashable {
    case preferences
    case models
    case privacy
}

@MainActor
struct SettingsView: View {
    var activeTab: SettingsTab?

    @State private var preference: EnginePreference = .current()
    @State private var modelManager = LocalModelManager()
    @State private var statuses: [String: LocalModelStatus] = [:]
    @State private var errorMessage: String?

    init(activeTab: SettingsTab? = nil) {
        self.activeTab = activeTab
    }

    var body: some View {
        #if os(iOS)
        iOSBody
        #else
        macOSBody
        #endif
    }
}

extension SettingsView {
    private var iOSBody: some View {
        NavigationStack {
            Form {
                engineSection
                modelsSection
                privacySection
            }
            .navigationTitle("Settings")
        }
        .task {
            await refreshStatuses()
        }
    }

    private var macOSBody: some View {
        NavigationStack {
            Form {
                switch activeTab {
                case .preferences, .none:
                    engineSection
                case .models:
                    modelsSection
                case .privacy:
                    privacySection
                }
            }
            .navigationTitle(navigationTitle)
        }
        .task {
            await refreshStatuses()
        }
    }

    private var navigationTitle: String {
        switch activeTab {
        case .preferences, .none: "Preferences"
        case .models: "Local Models"
        case .privacy: "Privacy & About"
        }
    }

    private var engineSection: some View {
        Section {
            Picker("Engine", selection: $preference) {
                ForEach(EnginePreference.allCases, id: \.self) { engine in
                    Text(engine.displayName).tag(engine)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: preference) { _, newValue in
                newValue.save()
            }

            #if os(macOS)
            Text("Configure which local NLP parser is active for event parsing.")
                .font(.uCaption2)
                .foregroundStyle(Color.secondaryLabel)
            #endif
        } header: {
            HStack(spacing: .spacing(.xSmall)) {
                Image(systemName: Icons.engine)
                Text("AI Engine Preference")
            }
        }
    }

    private var modelsSection: some View {
        Section {
            ForEach(LocalModel.allModels) { model in
                LocalModelRow(
                    model: model,
                    status: statuses[model.id] ?? .notDownloaded
                ) {
                    Task {
                        await download(model)
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.uCaption)
                    .foregroundStyle(Color.negative)
            }
        } header: {
            HStack(spacing: .spacing(.xSmall)) {
                Image(systemName: Icons.model)
                Text("Local MLX Models")
            }
        } footer: {
            Text(
                "Quantized Llama models run entirely on-device for secure NLP processing. " +
                "Models are downloaded from Hugging Face on first use."
            )
        }
    }

    private var privacySection: some View {
        Section {
            VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
                Text(
                    "Uniks is built local-first. Your personal event history, habits, " +
                    "and AI parsing logs are processed and stored exclusively on your " +
                    "physical device. We collect zero telemetry, zero analytics, " +
                    "and zero personal information. On-device models are downloaded from Hugging Face."
                )
                .font(.uFootnote)
                .foregroundStyle(Color.secondaryLabel)
                .lineSpacing(3)

                Divider()
                    .padding(.vertical, .spacing(.xxSmall))

                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(Color.secondaryLabel)
                }
                .font(.uCaption)
            }
            .padding(.vertical, .spacing(.xxSmall))
        } header: {
            HStack(spacing: .spacing(.xSmall)) {
                Image(systemName: Icons.privacy)
                Text("Privacy & About")
            }
        }
    }

    private func refreshStatuses() async {
        await modelManager.refreshStatuses()
        statuses = await modelManager.statuses
    }

    private func download(_ model: LocalModel) async {
        statuses[model.id] = .downloading
        await modelManager.download(model)
        statuses = await modelManager.statuses
    }
}
