//
//  SidebarView.swift
//  uniks
//
//  Left pane navigation sidebar for macOS three-pane split view.
//

import SwiftUI
import SwiftData

enum SidebarSelection: Hashable {
    case all
    case inbox
    case dashboard
    case settings
    case category(String)

    var displayName: String {
        switch self {
        case .all: return "All Events"
        case .inbox: return "Inbox"
        case .dashboard: return "Dashboard"
        case .settings: return "Settings"
        case .category(let name): return name
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarSelection?
    let onAddNewEvent: () -> Void

    @Query(sort: \HabitEvent.createdAt, order: .reverse) private var events: [HabitEvent]

    var body: some View {
        VStack(spacing: 0) {
            // Uniks logo header
            HStack(spacing: .spacing(.small)) {
                Image(systemName: Icons.sparkles)
                    .font(.uBrandTitle2)
                    .foregroundStyle(Gradients.logo)

                Text("Uniks")
                    .font(.uBrandBodyBold)
                    .foregroundStyle(Color.primaryLabel) +
                Text(" Offline Intelligence")
                    .font(.uBrandBodyMedium)
                    .foregroundStyle(Color.secondaryLabel)
            }
            .padding(.horizontal, .spacing(.medium))
            .padding(.top, .spacing(.medium))
            .padding(.bottom, .spacing(.xxSmall))
            .frame(maxWidth: .infinity, alignment: .leading)

            // New Event Button at the top of the sidebar
            Button(action: onAddNewEvent) {
                HStack {
                    Image(systemName: Icons.add)
                        .fontWeight(.semibold)
                    Text("New Event")
                        .fontWeight(.medium)
                    Spacer()
                    Text("⌘K")
                        .font(.uMonospacedCaption)
                        .opacity(0.6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacing(.xxSmall))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accent)
            .padding(.horizontal, .spacing(.medium))
            .padding(.top, .spacing(.medium))
            .padding(.bottom, .spacing(.small))
            .keyboardShortcut("k", modifiers: .command)

            List(selection: $selection) {
                Section("Library") {
                    NavigationLink(value: SidebarSelection.all) {
                        Label("All Events", systemImage: Icons.events)
                    }

                    NavigationLink(value: SidebarSelection.inbox) {
                        Label {
                            HStack {
                                Text("Inbox")
                                Spacer()
                                let count = inboxCount
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.uCaption)
                                        .foregroundStyle(Color.secondaryLabel)
                                        .padding(.horizontal, .spacing(.xSmall))
                                        .padding(.vertical, .spacing(.xxxSmall))
                                        .background(Color.tertiaryGroupedBackground, in: Capsule())
                                }
                            }
                        } icon: {
                            Image(systemName: Icons.trayAndArrowDown)
                        }
                    }

                    DisclosureGroup("Categories") {
                        let sortedCategories = categoryCounts.keys.sorted()
                        if sortedCategories.isEmpty {
                            Text("No categories")
                                .font(.uFootnote)
                                .foregroundStyle(Color.secondaryLabel)
                                .padding(.leading, .spacing(.small))
                        } else {
                            ForEach(sortedCategories, id: \.self) { category in
                                NavigationLink(value: SidebarSelection.category(category)) {
                                    Label {
                                        HStack {
                                            Text(category)
                                            Spacer()
                                            if let count = categoryCounts[category], count > 0 {
                                                Text("\(count)")
                                                    .font(.uCaption)
                                                    .foregroundStyle(Color.secondaryLabel)
                                                    .padding(.horizontal, .spacing(.xSmall))
                                                    .padding(.vertical, .spacing(.xxxSmall))
                                                    .background(Color.tertiaryGroupedBackground, in: Capsule())
                                            }
                                        }
                                    } icon: {
                                        Image(systemName: Icons.categorySymbol(for: category))
                                            .foregroundStyle(Color.categoryColor(for: category))
                                    }
                                }
                            }
                        }
                    }

                    NavigationLink(value: SidebarSelection.dashboard) {
                        Label("Dashboard", systemImage: Icons.dashboard)
                    }

                    NavigationLink(value: SidebarSelection.settings) {
                        Label("Settings", systemImage: Icons.settings)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Engine status (deep-links to Settings > Models)
            Button {
                selection = .settings
            } label: {
                UEngineStatusBadge(
                    modelName: activeModelName,
                    status: engineStatusState
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.spacing(.small))
                .background(
                    RoundedRectangle(cornerRadius: .radius(.medium))
                        .fill(Color.brandBlueBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: .radius(.medium))
                        .stroke(Color.brandBlueBorder, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, .spacing(.medium))
            .padding(.bottom, .spacing(.medium))
        }
    }

    // MARK: - Computed Properties & Helpers

    private var activeModelName: String {
        let modelID = ActiveModelPreference.effectiveModelID()
        return LocalModel.allModels.first(where: { $0.id == modelID })?.name ?? "Mock"
    }

    private var engineStatusState: UEngineStatusBadge.EngineStatusState {
        let pref = EnginePreference.current()
        switch pref {
        case .mlx: return .ready
        case .ollama: return .ready
        case .mock: return .mock
        }
    }

    private var inboxCount: Int {
        events.filter { $0.state == .pending }.count
    }

    private var categoryCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for event in events {
            if let category = event.parsedPayload()?.category?
                .trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
                let formatted = category.capitalized
                counts[formatted, default: 0] += 1
            }
        }
        return counts
    }
}
