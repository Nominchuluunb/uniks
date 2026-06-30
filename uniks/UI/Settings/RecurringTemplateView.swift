//
//  RecurringTemplateView.swift
//  uniks
//
//  UI for managing recurring event templates and notifications.
//

import SwiftUI
import SwiftData

@MainActor
struct RecurringTemplateView: View {
    @Query(sort: \RecurringTemplate.createdAt) private var templates: [RecurringTemplate]
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingCreate = false
    let notificationService: NotificationService

    var body: some View {
        NavigationStack {
            List {
                if templates.isEmpty {
                    Section {
                        VStack(spacing: .spacing(.medium)) {
                            Image(systemName: "bell.badge")
                                .font(.uLargeIcon)
                                .foregroundStyle(Gradients.brand)
                            Text("No Recurring Templates")
                                .font(.uHeadline)
                            Text("Create templates for habits you want to track regularly. Get reminded to log them.")
                                .font(.uCallout)
                                .foregroundStyle(Color.secondaryLabel)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .spacing(.xxLarge))
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section("Active") {
                        ForEach(templates.filter(\.isActive)) { template in
                            TemplateRow(template: template, notificationService: notificationService)
                        }
                        .onDelete { offsets in
                            deleteTemplates(at: offsets, active: true)
                        }
                    }

                    let inactive = templates.filter { !$0.isActive }
                    if !inactive.isEmpty {
                        Section("Inactive") {
                            ForEach(inactive) { template in
                                TemplateRow(template: template, notificationService: notificationService)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recurring Templates")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingCreate = true
                    } label: {
                        Image(systemName: Icons.add)
                    }
                    .accessibilityLabel("Create recurring template")
                }
            }
            .sheet(isPresented: $isShowingCreate) {
                CreateTemplateSheet(notificationService: notificationService)
            }
        }
    }

    private func deleteTemplates(at offsets: IndexSet, active: Bool) {
        let source = active ? templates.filter(\.isActive) : templates.filter { !$0.isActive }
        for index in offsets {
            let template = source[index]
            Task { await notificationService.removeNotification(for: template.id) }
            modelContext.delete(template)
        }
        try? modelContext.save()
    }
}

private struct TemplateRow: View {
    @Bindable var template: RecurringTemplate
    let notificationService: NotificationService

    var body: some View {
        HStack(spacing: .spacing(.small)) {
            Text(template.emoji)
                .font(.uBrandTitle2)

            VStack(alignment: .leading, spacing: .spacing(.xxxSmall)) {
                Text(template.phrase)
                    .font(.uBody)
                    .fontWeight(.medium)
                HStack(spacing: .spacing(.xxSmall)) {
                    Text(template.frequency.displayName)
                        .font(.uCaption2)
                        .foregroundStyle(Color.secondaryLabel)
                    if template.notificationEnabled {
                        Image(systemName: "bell.fill")
                            .font(.uCaption2)
                            .foregroundStyle(Color.accent)
                    }
                    Text("at \(formattedTime)")
                        .font(.uCaption2)
                        .foregroundStyle(Color.secondaryLabel)
                }
            }

            Spacer()

            Toggle("", isOn: $template.isActive)
                .labelsHidden()
                .onChange(of: template.isActive) { _, isActive in
                    let snapshot = template.snapshot
                    Task {
                        if isActive {
                            await notificationService.schedule(template: snapshot)
                        } else {
                            await notificationService.removeNotification(for: snapshot.id)
                        }
                    }
                }
        }
    }

    private var formattedTime: String {
        let hour = template.hour
        let minute = template.minute
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

private struct CreateTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let notificationService: NotificationService

    @State private var phrase = ""
    @State private var emoji = "⚡"
    @State private var category = ""
    @State private var frequency: TemplateFrequency = .daily
    @State private var hour = 9
    @State private var minute = 0
    @State private var notificationEnabled = true

    private let emojis = ["⚡", "💧", "🏃", "📚", "🧘", "💪", "🍎", "💊", "✍️", "😴"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    TextField("What to log (e.g. 'Drank water')", text: $phrase)
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

                    TextField("Category (optional)", text: $category)
                        .premiumTextFieldStyle()
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(TemplateFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    HStack {
                        Text("Time")
                        Spacer()
                        Picker("Hour", selection: $hour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h)").tag(h)
                            }
                        }
                        .labelsHidden()
                        Text(":")
                        Picker("Minute", selection: $minute) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .labelsHidden()
                    }

                    Toggle("Enable Notifications", isOn: $notificationEnabled)
                }
            }
            .navigationTitle("New Template")
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
                        .disabled(phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let template = RecurringTemplate(
            phrase: phrase.trimmingCharacters(in: .whitespacesAndNewlines),
            emoji: emoji,
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            frequency: frequency,
            hour: hour,
            minute: minute,
            notificationEnabled: notificationEnabled
        )
        modelContext.insert(template)
        try? modelContext.save()

        if notificationEnabled {
            let snapshot = template.snapshot
            Task {
                await notificationService.requestAuthorization()
                await notificationService.schedule(template: snapshot)
            }
        }

        dismiss()
    }
}
