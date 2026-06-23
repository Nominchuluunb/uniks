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
struct UniksApp: App {
    private let container: ModelContainer
    private let ftsService: any FTSServiceProtocol
    private let service: HabitEventService

    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    init() {
        do {
            self.container = try ModelContainer.uniksContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let preference = EnginePreference.current()
        let engine: any LocalLLMEngine
        switch preference {
        case .mlx:
            #if targetEnvironment(simulator)
            engine = OllamaLLMEngine() ?? MockLLMEngine(result: HabitParseResult())
            #else
            engine = MLXLLMEngine()
            #endif
        case .ollama:
            engine = OllamaLLMEngine() ?? MockLLMEngine(result: HabitParseResult())
        case .mock:
            engine = MockLLMEngine(result: HabitParseResult())
        }

        let ftsService: any FTSServiceProtocol
        do {
            let fileManager = FileManager.default
            guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                fatalError("Unable to locate application support directory")
            }
            let uniksDir = appSupport.appendingPathComponent("uniks", isDirectory: true)
            try fileManager.createDirectory(at: uniksDir, withIntermediateDirectories: true)
            let ftsURL = uniksDir.appendingPathComponent("fts.sqlite")
            ftsService = try FTSService(path: ftsURL)
        } catch {
            ftsService = FTSService.inMemory()
        }
        self.ftsService = ftsService

        let parser = ParsingActor(container: self.container, engine: engine)
        self.service = HabitEventService(
            container: self.container,
            parsingActor: parser,
            ftsService: self.ftsService
        )

        #if os(macOS)
        let viewModel = QuickInputViewModel(service: self.service)
        let panelManager = QuickInputPanelManager(viewModel: viewModel)
        panelManager.install()
        self.appDelegate.panelManager = panelManager
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(container: self.container, ftsService: self.ftsService)
        }
        .modelContainer(self.container)
    }
}

#if os(macOS)
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var panelManager: QuickInputPanelManager?
}
#endif
