//
//  SettingsView.swift
//  uniks
//
//  User settings for engine selection, local model management, and app info.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
enum SettingsTab: Hashable {
    case preferences
    case models
    case privacy
}

@MainActor
struct SettingsView: View {
    var activeTab: SettingsTab?

    @Environment(\.modelContext) private var modelContext
    @State private var preference: EnginePreference = .current()
    @State private var modelManager = LocalModelManager()
    @State private var statuses: [String: LocalModelStatus] = [:]
    @State private var activeModelID: String? = ActiveModelPreference.current()
    @State private var themePreference: ThemePreference = .current()
    @State private var isShowingExport = false
    @State private var isShowingImport = false
    @State private var isShowingCategories = false
    @State private var isShowingTemplates = false
    @State private var exportFormat: ExportFormat = .json
    @State private var exportData: Data?

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
                appearanceSection
                categoriesSection
                templatesSection
                dataExportSection
                keyboardShortcutsSection
                privacySection
            }
            .navigationTitle("Settings")
        }
        .task { await refreshStatuses() }
        .sheet(isPresented: $isShowingCategories) {
            CategoryManagementView()
        }
        .sheet(isPresented: $isShowingImport) {
            ImportView(importService: ImportService(container: modelContainer, ftsService: ftsService))
        }
        .fileExporter(
            isPresented: $isShowingExport,
            document: ExportDocument(data: exportData ?? Data()),
            contentType: exportFormat == .json ? .json : .commaSeparatedText,
            defaultFilename: "uniks-export.\(exportFormat.fileExtension)"
        ) { _ in }
        .task(id: isShowingExport) {
            if isShowingExport {
                let exportService = ExportService(container: modelContainer)
                exportData = try? await exportService.export(format: exportFormat)
            }
        }
    }

    private var macOSBody: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing(.large)) {
                    switch activeTab {
                    case .preferences, .none:
                        engineSection
                    case .models:
                        modelsSection
                    case .privacy:
                        privacySection
                    }
                }
                .padding(.spacing(.large))
            }
            .background(Color.groupedBackground)
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
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            USectionHeader(icon: Icons.engine, title: "AI Engine Preference")

            VStack(alignment: .leading, spacing: .spacing(.small)) {
                Picker("Engine", selection: $preference) {
                    ForEach(EnginePreference.allCases, id: \.self) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: preference) { _, newValue in
                    newValue.save()
                }

                Text("Configure which local NLP parser is active for event parsing.")
                    .font(.uCaption2)
                    .foregroundStyle(Color.secondaryLabel)
            }
            .padding(.spacing(.medium))
            .background(Color.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))
        }
    }

    // MARK: - Models Section

    private var modelsSection: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            USectionHeader(icon: Icons.model, title: "Local Gemma Models")

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
            }

            Text(
                "Gemma models run entirely on-device for private NLP parsing. " +
                "Models are downloaded from Hugging Face on first use. No personal data is sent."
            )
            .font(.uCaption2)
            .foregroundStyle(Color.secondaryLabel)
            .padding(.top, .spacing(.xxSmall))
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            USectionHeader(icon: Icons.privacy, title: "Privacy & About")

            VStack(alignment: .leading, spacing: .spacing(.small)) {
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

                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(Color.secondaryLabel)
                }
                .font(.uCaption)
            }
            .padding(.spacing(.medium))
            .background(Color.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            USectionHeader(icon: "paintbrush", title: "Appearance")

            VStack(alignment: .leading, spacing: .spacing(.small)) {
                Picker("Theme", selection: $themePreference) {
                    ForEach(ThemePreference.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: themePreference) { _, newValue in
                    newValue.save()
                }

                Text("Match your system appearance or choose a preferred theme.")
                    .font(.uCaption2)
                    .foregroundStyle(Color.secondaryLabel)
            }
            .padding(.spacing(.medium))
            .background(Color.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))
        }
    }

    // MARK: - Data Export Section

    private var dataExportSection: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            USectionHeader(icon: "square.and.arrow.up", title: "Data Export & Import")

            VStack(alignment: .leading, spacing: .spacing(.small)) {
                Text("Export all your events as JSON or CSV for backup or analysis. Import from files.")
                    .font(.uFootnote)
                    .foregroundStyle(Color.secondaryLabel)

                HStack(spacing: .spacing(.small)) {
                    UButton("Export JSON", style: .secondary) {
                        isShowingExport = true
                        exportFormat = .json
                    }
                    UButton("Export CSV", style: .secondary) {
                        isShowingExport = true
                        exportFormat = .csv
                    }
                    UButton("Import", style: .secondary) {
                        isShowingImport = true
                    }
                }
            }
            .padding(.spacing(.medium))
            .background(Color.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))
        }
    }

    // MARK: - Keyboard Shortcuts Section

    private var keyboardShortcutsSection: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            USectionHeader(icon: "keyboard", title: "Keyboard Shortcuts")

            VStack(spacing: .spacing(.xSmall)) {
                shortcutRow(keys: "⌘ ⇧ U", action: "Open Quick Input")
                shortcutRow(keys: "⌘ K", action: "New Event (sidebar)")
                shortcutRow(keys: "↵", action: "Save event")
                shortcutRow(keys: "Esc", action: "Dismiss HUD")
            }
            .padding(.spacing(.medium))
            .background(Color.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))
        }
    }

    private func shortcutRow(keys: String, action: String) -> some View {
        HStack {
            Text(action)
                .font(.uCallout)
            Spacer()
            Text(keys)
                .font(.uMonospacedCaption)
                .foregroundStyle(Color.secondaryLabel)
                .padding(.horizontal, .spacing(.xSmall))
                .padding(.vertical, .spacing(.xxxSmall))
                .background(Color.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: .radius(.small)))
        }
    }

    // MARK: - Actions

    private var modelContainer: ModelContainer {
        modelContext.container
    }

    private var ftsService: any FTSServiceProtocol {
        FTSService.inMemory()
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            USectionHeader(icon: "folder.fill", title: "Categories")

            VStack(alignment: .leading, spacing: .spacing(.small)) {
                Text("Manage, rename, merge, and customize category colors.")
                    .font(.uFootnote)
                    .foregroundStyle(Color.secondaryLabel)

                UButton("Manage Categories", style: .secondary) {
                    isShowingCategories = true
                }
            }
            .padding(.spacing(.medium))
            .background(Color.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))
        }
    }

    // MARK: - Templates Section

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: .spacing(.small)) {
            USectionHeader(icon: "bell.badge", title: "Recurring Templates")

            VStack(alignment: .leading, spacing: .spacing(.small)) {
                Text("Set up recurring reminders to log your habits consistently.")
                    .font(.uFootnote)
                    .foregroundStyle(Color.secondaryLabel)

                UButton("Manage Templates", style: .secondary) {
                    isShowingTemplates = true
                }
            }
            .padding(.spacing(.medium))
            .background(Color.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: .radius(.medium)))
        }
    }

    // MARK: - Refresh & Model Actions

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
