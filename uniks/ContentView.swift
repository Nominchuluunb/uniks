//
//  ContentView.swift
//  uniks
//
//  Temporary shared dashboard placeholder. The real HUD and Dashboard views
//  will be generated after user confirmation.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitEvent.createdAt, order: .reverse) private var events: [HabitEvent]

    let container: ModelContainer

    var body: some View {
        NavigationStack {
            List(events) { event in
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.rawInput)
                        .font(.body)
                    HStack {
                        StatusBadge(state: event.state)
                        Spacer()
                        Text(event.createdAt, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Uniks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log Test", systemImage: "plus") {
                        logTestEvent()
                    }
                }
            }
        }
    }

    private func logTestEvent() {
        let event = HabitEvent(rawInput: "Ran 5km in 28 minutes")
        modelContext.insert(event)

        // Optimistic UI: the event is already saved; parsing happens in the background.
        let eventID = event.id
        let engine = MockLLMEngine(
            result: HabitParseResult(
                category: "fitness",
                value: 5,
                unit: "km",
                tags: ["run"],
                notes: "felt strong"
            )
        )

        Task {
            let parser = ParsingActor(container: container, engine: engine)
            await parser.parseAndSave(eventID: eventID)
        }
    }
}

#Preview {
    let container = try! ModelContainer.uniksContainer(inMemory: true)
    ContentView(container: container)
        .modelContainer(container)
}
