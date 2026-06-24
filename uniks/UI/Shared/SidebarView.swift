//
//  SidebarView.swift
//  uniks
//
//  Left pane navigation sidebar for macOS Three-Pane Split View.
//

import SwiftUI
import SwiftData
import Combine

enum SidebarSelection: Hashable {
    case all
    case inbox
    case dashboard
    case settings
    case category(String)
    case saved(SavedFilter)
    
    var displayName: String {
        switch self {
        case .all: return "All Events"
        case .inbox: return "Inbox"
        case .dashboard: return "Dashboard"
        case .settings: return "Settings"
        case .category(let name): return name
        case .saved(let filter): return filter.rawValue
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarSelection?
    let onAddNewEvent: () -> Void
    
    @Query(sort: \HabitEvent.createdAt, order: .reverse) private var events: [HabitEvent]
    @State private var preference: EnginePreference = .current()
    @State private var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Uniks logo header
            HStack(spacing: .spacing(.small)) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Uniks")
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.primaryLabel) +
                Text(" Offline Intelligence")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(Color.secondaryLabel)
            }
            .padding(.horizontal, .spacing(.medium))
            .padding(.top, .spacing(.medium))
            .padding(.bottom, .spacing(.xxSmall))
            .frame(maxWidth: .infinity, alignment: .leading)
            // New Event Button at the top of the sidebar
            Button(action: onAddNewEvent) {
                HStack {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                    Text("New Event")
                        .fontWeight(.medium)
                    Spacer()
                    Text("⌘K")
                        .font(.system(.caption, design: .monospaced))
                        .opacity(0.6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacing(.xxSmall))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            .padding(.horizontal, .spacing(.medium))
            .padding(.top, .spacing(.medium))
            .padding(.bottom, .spacing(.small))
            .keyboardShortcut("k", modifiers: .command)
            
            List(selection: $selection) {
                Section("Library") {
                    NavigationLink(value: SidebarSelection.all) {
                        Label("All Events", systemImage: "list.bullet")
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
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.tertiaryGroupedBackground, in: Capsule())
                                }
                            }
                        } icon: {
                            Image(systemName: "tray.and.arrow.down.fill")
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
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
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
                
                Section("Saved") {
                    ForEach(SavedFilter.allCases, id: \.self) { filter in
                        NavigationLink(value: SidebarSelection.saved(filter)) {
                            Label {
                                HStack {
                                    Text(filter.rawValue)
                                    Spacer()
                                    let count = savedFilterCount(for: filter)
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.uCaption)
                                            .foregroundStyle(Color.secondaryLabel)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.tertiaryGroupedBackground, in: Capsule())
                                    }
                                }
                            } icon: {
                                Image(systemName: savedFilterIcon(for: filter))
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            
            Divider()
            
            // Bottom status area
            Button {
                selection = .settings
            } label: {
                HStack(spacing: .spacing(.small)) {
                    Image(systemName: "sparkles")
                        .font(.body)
                        .foregroundStyle(Color.blue)
                        .padding(.spacing(.xxSmall))
                        .background(Color.blue.opacity(0.1), in: Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Local, offline intelligence")
                            .font(.system(size: 10, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.primaryLabel)
                        Text("powered by Gemma")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(Color.secondaryLabel)
                    }
                    
                    Spacer()
                }
                .padding(.spacing(.small))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.12), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, .spacing(.medium))
            .padding(.bottom, .spacing(.medium))
        }
        .onReceive(timer) { _ in
            let latest = EnginePreference.current()
            if latest != preference {
                preference = latest
            }
        }
    }
    
    // MARK: - Computed Properties & Helpers
    
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
    
    private func savedFilterCount(for filter: SavedFilter) -> Int {
        events.filter { $0.matchesSavedFilter(filter) }.count
    }
    
    private func savedFilterIcon(for filter: SavedFilter) -> String {
        switch filter {
        case .prsThisYear: return "trophy.fill"
        case .civicServiceLog: return "wrench.and.screwdriver.fill"
        case .longRuns: return "figure.run"
        }
    }
}
