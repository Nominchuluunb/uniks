//
//  uniksApp.swift
//  uniks
//
//  App entry point with platform-specific HUD wiring.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

@main
struct uniksApp: App {
    private let container: ModelContainer
    private let service: HabitEventService

    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    init() {
        self.container = (try? ModelContainer.uniksContainer()) ?? ModelContainer.uniksContainer(inMemory: true)

        let engine = MockLLMEngine(result: HabitParseResult())
        let parser = ParsingActor(container: container, engine: engine)
        let fts = FTSService.inMemory()
        self.service = HabitEventService(container: container, parsingActor: parser, ftsService: fts)

        #if os(macOS)
        let viewModel = QuickInputViewModel(service: service)
        let panelManager = QuickInputPanelManager(viewModel: viewModel)
        panelManager.install()
        appDelegate.panelManager = panelManager
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(container: container, service: service)
        }
        .modelContainer(container)
    }
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    var panelManager: QuickInputPanelManager?
}
#endif
