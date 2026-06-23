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
    @State private var eventListViewModel: EventListViewModel

    init(ftsService: any FTSServiceProtocol) {
        self.ftsService = ftsService
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
    }
}

#Preview {
    do {
        let container = try ModelContainer.uniksContainer(inMemory: true)
        let ftsService = FTSService.inMemory()
        return AnyView(
            ContentView(ftsService: ftsService)
                .modelContainer(container)
        )
    } catch {
        return AnyView(Text("Preview failed"))
    }
}
