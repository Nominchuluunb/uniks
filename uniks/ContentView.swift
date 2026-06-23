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

    init(ftsService: any FTSServiceProtocol) {
        self.ftsService = ftsService
    }

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
        let ftsService = FTSService.inMemory()
        return AnyView(
            ContentView(ftsService: ftsService)
                .modelContainer(container)
        )
    } catch {
        return AnyView(Text("Preview failed"))
    }
}
