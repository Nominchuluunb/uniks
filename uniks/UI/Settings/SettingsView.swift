//
//  SettingsView.swift
//  uniks
//
//  User settings for engine selection, local model management, and app info.
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
    @State private var activeModelID: String? = ActiveModelPreference.current()

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
        .task { await refreshStatuses() }
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
        .task { await refreshStatuses() }
    }

    private var navigationTitle: String {
        switch activeTab {
        case .preferences, .none: "Preferences"
        case .models: "Local Models"
        case .privacy: "Privacy & About"
        }
    }

    // MARK: - Engine Section

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
            USectionHeader(icon: Icons.engine, title: "AI Engine Preference")
        }
    }

    // MARK: - Models Section

    private var modelsSection: some View {
        Section {
            ForEach(LocalModel.allModels) { model in
                UModelCard(
                    model: model,
                    status: statuses[model.id] ?? .notDownloaded,
                    isActive: activeModelID == model.id
                        || (activeModelID == nil && model.isDefault),
                    onDownload: { startDownload(model) },
                    onCancel: { cancelDownload(model) },
                    onDelete: { deleteModel(model) },
                    onRetry: { startDownload(model) },
                    onActivate: { activateModel(model) }
                )
                .listRowInsets(EdgeInsets(
                    top: .spacing(.xSmall),
                    leading: .spacing(.xSmall),
                    bottom: .spacing(.xSmall),
                    trailing: .spacing(.xSmall)
                ))
                .listRowSeparator(.hidden)
            }
        } header: {
            USectionHeader(icon: Icons.model, title: "Local Gemma Models")
        } footer: {
            Text(
                "Gemma models run entirely on-device for private NLP parsing. " +
                "Models are downloaded from Hugging Face on first use. No personal data is sent."
            )
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
                Text(
                    "Uniks is built local-first. Your personal event history, habits, " +
                    "and AI parsing logs are processed and stored exclusively on your " +
                    "physical device. We collect zero telemetry, zero analytics, " +
                    "and zero personal information."
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
            USectionHeader(icon: Icons.privacy, title: "Privacy & About")
        }
    }

    // MARK: - Actions

    private func refreshStatuses() async {
        await modelManager.refreshStatuses()
        statuses = await modelManager.statuses
        activeModelID = ActiveModelPreference.current()
    }

    private func startDownload(_ model: LocalModel) {
        let stream = Task { await modelManager.download(model) }
        Task {
            let progressStream = await stream.value
            for await progress in progressStream {
                statuses[model.id] = .downloading(progress)
            }
            statuses = await modelManager.statuses
            activeModelID = ActiveModelPreference.current()
        }
    }

    private func cancelDownload(_ model: LocalModel) {
        Task {
            await modelManager.cancelDownload(model)
            statuses = await modelManager.statuses
        }
    }

    private func deleteModel(_ model: LocalModel) {
        Task {
            await modelManager.deleteModel(model)
            statuses = await modelManager.statuses
            activeModelID = ActiveModelPreference.current()
        }
    }

    private func activateModel(_ model: LocalModel) {
        ActiveModelPreference.setActive(model.id)
        activeModelID = model.id
    }
}
