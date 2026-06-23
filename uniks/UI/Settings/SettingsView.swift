//
//  SettingsView.swift
//  uniks
//
//  User settings for engine selection and data export.
//

import SwiftUI

struct SettingsView: View {
    @State private var preference: EnginePreference = .current()

    var body: some View {
        NavigationStack {
            Form {
                Section("AI Engine") {
                    Picker("Engine", selection: $preference) {
                        ForEach(EnginePreference.allCases, id: \.self) { engine in
                            Text(engine.displayName).tag(engine)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: preference) { _, newValue in
                        newValue.save()
                    }
                }

                Section("About") {
                    Text("Uniks keeps your data on your device. No telemetry, no cloud LLMs by default.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
