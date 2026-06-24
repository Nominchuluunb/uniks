//
//  SettingsControls.swift
//  uniks
//
//  Created by AI Agent.
//  Subviews and controls used inside SettingsView.
//

import SwiftUI

struct LocalModelRow: View {
    let model: LocalModel
    let status: LocalModelStatus
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Text(status.displayText)
                        .font(.uCaption)
                        .foregroundStyle(Color.secondaryLabel)
                }

                Spacer()

                switch status {
                case .notDownloaded:
                    Button {
                        onDownload()
                    } label: {
                        Text("Download")
                            .font(.uCaption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, .spacing(.medium))
                            .padding(.vertical, .spacing(.xxSmall))
                            .background(Gradients.brand, in: Capsule())
                            .shadow(color: Color.accentColor.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .interactiveScale()
                case .downloading:
                    EmptyView()
                case .downloaded:
                    Image(systemName: Icons.success)
                        .font(.title3)
                        .foregroundStyle(Color.positive)
                }
            }
            
            if case .downloading = status {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(Color.accentColor)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, .spacing(.xxSmall))
    }
}

struct SettingsDropdownPicker<T: Hashable>: View {
    let title: String
    let selection: Binding<T>
    let options: [T]
    let formatter: (T) -> String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(Color.primaryLabel)
            
            Spacer()
            
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(formatter(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .padding(.horizontal, .spacing(.medium))
        .padding(.vertical, .spacing(.small))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.tertiaryGroupedBackground.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.separator.opacity(0.3), lineWidth: 0.8)
        )
    }
}

struct SettingsToggleRow: View {
    let title: String
    let description: String
    let isOn: Binding<Bool>
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.primaryLabel)
                Text(description)
                    .font(.uFootnote)
                    .foregroundStyle(Color.secondaryLabel)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, .spacing(.xxSmall))
    }
}
