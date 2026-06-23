//
//  ContentView.swift
//  uniks
//
//  Main tab container for event list and settings.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let container: ModelContainer
    let service: HabitEventService

    var body: some View {
        TabView {
            EventListView(viewModel: eventListViewModel())
                .tabItem {
                    Label("Events", systemImage: "list.bullet")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .modelContainer(container)
    }

    private func eventListViewModel() -> EventListViewModel {
        EventListViewModel(ftsService: FTSService.inMemory())
    }
}

#Preview {
    let container = try! ModelContainer.uniksContainer(inMemory: true)
    let engine = MockLLMEngine(result: HabitParseResult())
    let parser = ParsingActor(container: container, engine: engine)
    let service = HabitEventService(
        container: container,
        parsingActor: parser,
        ftsService: FTSService.inMemory()
    )
    ContentView(container: container, service: service)
        .modelContainer(container)
}
