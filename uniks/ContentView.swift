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
    let ftsService: any FTSServiceProtocol

    var body: some View {
        TabView {
            EventListView(viewModel: self.eventListViewModel())
                .tabItem {
                    Label("Events", systemImage: "list.bullet")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }

    private func eventListViewModel() -> EventListViewModel {
        EventListViewModel(ftsService: self.ftsService)
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
            ContentView(container: container, ftsService: ftsService)
                .modelContainer(container)
        )
    } catch {
        return AnyView(Text("Preview failed"))
    }
}
