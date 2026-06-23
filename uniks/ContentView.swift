//
//  ContentView.swift
//  uniks
//
//  Main tab container for event list and settings.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let ftsService: any FTSServiceProtocol
    let service: HabitEventService
    @State private var eventListViewModel: EventListViewModel
    @State private var isPresentingQuickInput = false

    init(ftsService: any FTSServiceProtocol, service: HabitEventService) {
        self.ftsService = ftsService
        self.service = service
        _eventListViewModel = State(
            wrappedValue: EventListViewModel(ftsService: ftsService)
        )
    }

    var body: some View {
        TabView {
            EventListView(viewModel: eventListViewModel)
                .tabItem {
                    Label("Events", systemImage: "list.bullet")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .primaryAction) {
                Button("Log", systemImage: "plus") {
                    isPresentingQuickInput = true
                }
            }
            #endif
        }
        .sheet(isPresented: $isPresentingQuickInput) {
            QuickInputSheet(
                viewModel: QuickInputViewModel(
                    service: service,
                    onSaved: { isPresentingQuickInput = false }
                )
            )
        }
    }
}

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
            ContentView(ftsService: ftsService, service: service)
                .modelContainer(container)
        )
    } catch {
        return AnyView(Text("Preview failed"))
    }
}
