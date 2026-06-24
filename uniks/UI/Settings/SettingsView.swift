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
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: Icons.engine)
                        Text("AI Engine Preference")
                    }
                }

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
                    HStack(spacing: 6) {
                        Image(systemName: Icons.model)
                        Text("Local MLX Models")
                    }
                } footer: {
                    Text(
                        "Quantized Llama models run entirely on-device for secure NLP processing. " +
                        "Models are downloaded from Hugging Face on first use."
                    )
                }

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
                    HStack(spacing: 6) {
                        Image(systemName: Icons.privacy)
                        Text("Privacy & About")
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .task {
            await refreshStatuses()
        }
    }

    private var macOSBody: some View {
        ScrollView {
            VStack(spacing: .spacing(.large)) {
                switch activeTab {
                case .preferences, .none:
                    UCard(title: "AI Engine Preference") {
                        VStack(alignment: .leading, spacing: .spacing(.medium)) {
                            Picker("Engine", selection: $preference) {
                                ForEach(EnginePreference.allCases, id: \.self) { engine in
                                    Text(engine.displayName).tag(engine)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .onChange(of: preference) { _, newValue in
                                newValue.save()
                            }

                            Text("Configure which local NLP parser is active for event parsing.")
                                .font(.uCaption2)
                                .foregroundStyle(Color.secondaryLabel)
                        }
                    }

                case .models:
                    UCard(title: "Local MLX Models") {
                        VStack(alignment: .leading, spacing: .spacing(.small)) {
                            ForEach(LocalModel.allModels) { model in
                                LocalModelRow(
                                    model: model,
                                    status: statuses[model.id] ?? .notDownloaded
                                ) {
                                    Task {
                                        await download(model)
                                    }
                                }

                                if model != LocalModel.allModels.last {
                                    Divider()
                                }
                            }

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.uCaption)
                                    .foregroundStyle(Color.negative)
                            }
                        }
                    }

                case .privacy:
                    UCard(title: "Privacy & About") {
                        VStack(alignment: .leading, spacing: .spacing(.medium)) {
                            Text(
                                "Uniks is built local-first. Your personal event history, habits, " +
                                "and AI parsing logs are processed and stored exclusively on your " +
                                "physical device. We collect zero telemetry, zero analytics, " +
                                "and zero personal information. On-device models are downloaded from Hugging Face."
                            )
                            .font(.uCallout)
                            .foregroundStyle(Color.secondaryLabel)
                            .lineSpacing(3)

                            Divider()

                            HStack {
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundStyle(Color.secondaryLabel)
                            }
                            .font(.uCaption)
                        }
                    }
                }
            }
            .padding(.spacing(.large))
        }
        .task {
            await refreshStatuses()
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
