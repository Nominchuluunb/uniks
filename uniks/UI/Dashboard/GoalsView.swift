//
//  GoalsView.swift
//  uniks
//
//  Goals progress rings and management UI.
//

import SwiftUI
import SwiftData

@MainActor
struct GoalsCard: View {
    let progress: [GoalProgress]
    var onAdd: (() -> Void)?

    var body: some View {
        UCard(title: "Goals") {
            if progress.isEmpty {
                VStack(spacing: .spacing(.small)) {
                    Text("Set a goal to track your habits")
                        .font(.uCallout)
                        .foregroundStyle(Color.secondaryLabel)
                    if let onAdd {
                        UButton("Add Goal", style: .secondary, action: onAdd)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: .spacing(.medium)) {
                    // Ring charts row
                    HStack(spacing: .spacing(.large)) {
                        ForEach(progress.prefix(3)) { item in
                            GoalRing(progress: item)
                        }
                    }

                    // Summary
                    let completed = progress.filter(\.isCompleted).count
                    if completed > 0 {
                        HStack(spacing: .spacing(.xxSmall)) {
                            Image(systemName: "trophy.fill")
                                .font(.uCaption)
                                .foregroundStyle(Color.warning)
                            Text("\(completed)/\(progress.count) goals completed this period")
                                .font(.uCaption)
                                .foregroundStyle(Color.secondaryLabel)
                        }
                    }
                }
            }
        }
    }
}

private struct GoalRing: View {
    let progress: GoalProgress

    var body: some View {
        VStack(spacing: .spacing(.xxSmall)) {
            ZStack {
                Circle()
                    .stroke(Color.tertiaryGroupedBackground, lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress.fractionCompleted)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress.fractionCompleted)

                VStack(spacing: 0) {
                    Text(progress.goal.emoji)
                        .font(.uBody)
                    Text("\(progress.currentCount)/\(progress.goal.targetCount)")
                        .font(.uNumeric)
                        .fontWeight(.bold)
                }
            }
            // swiftlint:disable:next hardcoded_frame_size
            .frame(width: 72, height: 72)

            Text(progress.goal.category.capitalized)
                .font(.uCaption2)
                .foregroundStyle(Color.secondaryLabel)
                .lineLimit(1)

            Text(progress.goal.goalFrequency.displayName)
                .font(.uTiny)
                .foregroundStyle(Color.secondaryLabelSubtle)
        }
        .frame(maxWidth: .infinity)
    }

    private var ringColor: Color {
        if progress.isCompleted { return .positive }
        if progress.fractionCompleted > 0.5 { return .accent }
        return .warning
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    let container: ModelContainer

    @State private var category = ""
    @State private var targetCount = 3
    @State private var frequency: GoalFrequency = .weekly
    @State private var emoji = "🎯"

    private let emojis = ["🎯", "🏃", "📚", "💧", "🧘", "💪", "🍎", "😴", "✍️", "🎨"]

    var body: some View {
        NavigationStack {
            Form {
                Section("What") {
                    TextField("Category (e.g. Fitness)", text: $category)
                        .premiumTextFieldStyle()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .spacing(.xSmall)) {
                            ForEach(emojis, id: \.self) { e in
                                Button {
                                    emoji = e
                                } label: {
                                    Text(e)
                                        .font(.uBrandTitle2)
                                        .padding(.spacing(.xxSmall))
                                        .background(
                                            emoji == e ? Color.accentSubtle : Color.clear,
                                            in: Circle()
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Target") {
                    Stepper("Count: \(targetCount)", value: $targetCount, in: 1...30)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(GoalFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Text("Goal: \(emoji) \(category.isEmpty ? "Category" : category) \(targetCount)x / \(frequency.displayName.lowercased())")
                        .font(.uBody)
                        .foregroundStyle(Color.primaryLabel)
                }
            }
            .navigationTitle("New Goal")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let context = ModelContext(container)
        let goal = Goal(category: trimmed, targetCount: targetCount, frequency: frequency, emoji: emoji)
        context.insert(goal)
        try? context.save()
        dismiss()
    }
}
