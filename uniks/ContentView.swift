//
//  ContentView.swift
//  uniks
//
//  Root container: iOS tab bar and macOS three-pane split view.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let container: ModelContainer
    let ftsService: any FTSServiceProtocol
    let service: HabitEventService
    let showQuickInput: (() -> Void)?
    
    @State private var eventListViewModel: EventListViewModel
    @State private var dashboardViewModel: DashboardViewModel
    @State private var isPresentingQuickInput = false
    @State private var isPresentingOnboarding: Bool
    
    // macOS NavigationSplitView states
    @State private var selectedSidebarSelection: SidebarSelection? = .all
    @State private var selectedEvent: HabitEvent?
    @State private var selectedSettingsTab: SettingsTab = .preferences
    
    #if os(iOS)
    @State private var selectedTab: TabSelection = .events
    #endif

    init(
        container: ModelContainer,
        ftsService: any FTSServiceProtocol,
        service: HabitEventService,
        showQuickInput: (() -> Void)? = nil
    ) {
        self.container = container
        self.ftsService = ftsService
        self.service = service
        self.showQuickInput = showQuickInput
        _eventListViewModel = State(
            wrappedValue: EventListViewModel(service: service, ftsService: ftsService)
        )
        _dashboardViewModel = State(
            wrappedValue: DashboardViewModel(container: container)
        )
        let skipOnboarding = CommandLine.arguments.contains("-skipOnboarding")
            || ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
        _isPresentingOnboarding = State(
            initialValue: !skipOnboarding
                && !UserDefaults.standard.bool(forKey: OnboardingView.completedKey)
        )
    }

    var body: some View {
        Group {
            #if os(macOS)
            NavigationSplitView {
                SidebarView(
                    selection: $selectedSidebarSelection,
                    onAddNewEvent: {
                        showQuickInput?()
                    }
                )
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            } content: {
                switch selectedSidebarSelection {
                case .all, .inbox, .category:
                    EventListView(
                        viewModel: eventListViewModel,
                        sidebarSelection: selectedSidebarSelection,
                        selectedEventBinding: $selectedEvent
                    )
                    .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 500)
                case .dashboard:
                    ContentUnavailableView(
                        "Dashboard",
                        systemImage: Icons.dashboard,
                        description: Text("Charts and summaries appear in the detail pane.")
                    )
                    .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
                case .settings:
                    List(selection: $selectedSettingsTab) {
                        NavigationLink(value: SettingsTab.preferences) {
                            Label("Preferences", systemImage: Icons.engine)
                        }
                        NavigationLink(value: SettingsTab.models) {
                            Label("Local Models", systemImage: Icons.model)
                        }
                        NavigationLink(value: SettingsTab.privacy) {
                            Label("Privacy & About", systemImage: Icons.privacy)
                        }
                    }
                    .navigationTitle("Settings")
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
                case .none:
                    Text("Select an option")
                }
            } detail: {
                switch selectedSidebarSelection {
                case .all, .inbox, .category:
                    InspectorView(event: selectedEvent, service: service)
                case .dashboard:
                    DashboardView(viewModel: dashboardViewModel)
                case .settings:
                    SettingsView(activeTab: selectedSettingsTab)
                case .none:
                    Text("Select an option")
                }
            }
            #else
            TabView(selection: $selectedTab) {
                EventListView(viewModel: eventListViewModel)
                    .tabItem {
                        Label("Events", systemImage: Icons.events)
                    }
                    .tag(TabSelection.events)

                DashboardView(viewModel: dashboardViewModel)
                    .tabItem {
                        Label("Dashboard", systemImage: Icons.dashboard)
                    }
                    .tag(TabSelection.dashboard)

                LogTabPlaceholder()
                    .tabItem {
                        Label("Log", systemImage: Icons.add)
                    }
                    .tag(TabSelection.log)
                    .accessibilityLabel("Log new event")

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: Icons.settings)
                    }
                    .tag(TabSelection.settings)
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .log {
                    isPresentingQuickInput = true
                    selectedTab = .events
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log", systemImage: Icons.add) {
                        isPresentingQuickInput = true
                    }
                    .accessibilityLabel("Log new event")
                }
            }
            #endif
        }
        #if os(iOS)
        .sheet(isPresented: $isPresentingQuickInput) {
            QuickInputSheet(
                viewModel: QuickInputViewModel(
                    service: service,
                    onSaved: { isPresentingQuickInput = false }
                )
            )
        }
        .fullScreenCover(isPresented: $isPresentingOnboarding) {
            OnboardingView(isPresented: $isPresentingOnboarding)
        }
        #else
        .sheet(isPresented: $isPresentingOnboarding) {
            OnboardingView(isPresented: $isPresentingOnboarding)
        }
        #endif
    }
}

#if os(iOS)
private enum TabSelection: Hashable {
    case events
    case dashboard
    case log
    case settings
}

private struct LogTabPlaceholder: View {
    var body: some View {
        Color.clear
            .accessibilityHidden(true)
    }
}
#endif

#Preview {
    do {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let engine = MockLLMEngine(result: HabitParseResult())
        let parser = ParsingActor(container: container, engine: engine)
        let ftsService = FTSService.inMemory()
        let service = HabitEventService(
            container: container,
            parsingActor: parser,
            ftsService: ftsService
        )
        return AnyView(
            ContentView(container: container, ftsService: ftsService, service: service, showQuickInput: nil)
                .modelContainer(container)
        )
    } catch {
        return AnyView(Text("Preview failed"))
    }
}
