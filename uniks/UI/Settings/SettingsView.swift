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
    @State private var dictationHotkey = "Right ⌘"
    @State private var dictationMicrophone = "MacBook Pro Microphone"
    @State private var onDeviceModel = "Gemma 4 12B Model"
    @State private var directTextInsertion = true
    @State private var instantTranscript = false
    @State private var hideFloatingBar = false
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
                        Image(systemName: "cpu")
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
                        Image(systemName: "square.3.layers.3d")
                        Text("Local MLX Models")
                    }
                } footer: {
                    Text("Quantized Llama & Phi models run entirely on-device for secure NLP processing.")
                }

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
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield")
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
                    VStack(alignment: .leading, spacing: .spacing(.large)) {
                        // Section 1: AI Engine Preference
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
                        
                        // Section 2: System Hotkeys
                        UCard(title: "System Hotkeys") {
                            VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                                Text("Customize keyboard shortcuts to trigger Uniks actions.")
                                    .font(.uFootnote)
                                    .foregroundStyle(Color.secondaryLabel)
                                    .padding(.bottom, 4)
                                
                                SettingsDropdownPicker(
                                    title: "Dictation Hotkey",
                                    selection: $dictationHotkey,
                                    options: ["Right ⌘", "Left ⌘", "Double ⌃"],
                                    formatter: { $0 }
                                )
                            }
                        }
                        
                        // Section 3: Dictation Microphone
                        UCard(title: "Dictation Microphone") {
                            VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                                Text("Select the microphone to use for dictation.")
                                    .font(.uFootnote)
                                    .foregroundStyle(Color.secondaryLabel)
                                    .padding(.bottom, 4)
                                
                                SettingsDropdownPicker(
                                    title: "Microphone",
                                    selection: $dictationMicrophone,
                                    options: ["MacBook Pro Microphone", "Built-in Microphone", "External Mic"],
                                    formatter: { $0 }
                                )
                            }
                        }
                        
                        // Section 4: On-Device Model
                        UCard(title: "On-Device Model") {
                            VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                                Text("Select which Gemma model to use for text style transforms and voice editing.")
                                    .font(.uFootnote)
                                    .foregroundStyle(Color.secondaryLabel)
                                    .padding(.bottom, 4)
                                
                                SettingsDropdownPicker(
                                    title: "Model Type",
                                    selection: $onDeviceModel,
                                    options: ["Gemma 4 12B Model", "Llama 3.2 1B Instruct", "Llama 3.2 3B Instruct"],
                                    formatter: { $0 }
                                )
                            }
                        }
                        
                        // Section 5: Dynamic Text Actions
                        UCard(title: "Text & HUD Preferences") {
                            VStack(spacing: .spacing(.medium)) {
                                SettingsToggleRow(
                                    title: "Direct Text Insertion",
                                    description: "When recording via the macOS floating panel, " +
                                        "directly insert the polished text into the text field.",
                                    isOn: $directTextInsertion
                                )
                                
                                Divider()
                                
                                SettingsToggleRow(
                                    title: "Instant Transcript (Skip polishing)",
                                    description: "Skip text polishing and get instant transcript " +
                                        "when recording via the macOS floating panel.",
                                    isOn: $instantTranscript
                                )
                                
                                Divider()
                                
                                SettingsToggleRow(
                                    title: "Hide floating bar after action finishes",
                                    description: "Automatically hide the macOS floating bar " +
                                        "after each action finishes.",
                                    isOn: $hideFloatingBar
                                )
                            }
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
                                "and zero personal information."
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
