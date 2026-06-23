//
//  uniksApp.swift
//  uniks
//
//  App entry point and shared ModelContainer setup.
//

import SwiftUI
import SwiftData

@main
struct uniksApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer.uniksContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
        .modelContainer(container)
    }
}
