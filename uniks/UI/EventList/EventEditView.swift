//
//  EventEditView.swift
//  uniks
//
//  Sheet for correcting AI-parsed fields with rich live preview.
//

import SwiftUI

@MainActor
struct EventEditView: View {
    let event: HabitEvent
    let service: HabitEventService
    let onFinished: () -> Void

    @State private var category: String
    @State private var value: String
    @State private var unit: String
    @State private var tags: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false

    init(event: HabitEvent, service: HabitEventService, onFinished: @escaping () -> Void) {
        self.event = event
        self.service = service
        self.onFinished = onFinished

        let payload = event.parsedPayload()
        _category = State(initialValue: payload?.category ?? "")
        _value = State(initialValue: payload?.value.map { String($0) } ?? "")
        _unit = State(initialValue: payload?.unit ?? "")
        _tags = State(initialValue: payload?.tags?.joined(separator: ", ") ?? "")
        _notes = State(initialValue: payload?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Raw input + status
                Section {
                    VStack(alignment: .leading, spacing: .spacing(.xSmall)) {
                        HStack {
                            Text(event.rawInput)
                                .font(.uBody)
                                .fontWeight(.medium)
                            Spacer()
                            UBadge(state: event.state)
                        }

                        Text(event.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                            .font(.uCaption2)
                            .foregroundStyle(Color.secondaryLabel)
                    }
                    .padding(.vertical, .spacing(.xxSmall))
                }

                // Live preview
                Section("Preview") {
                    UFlowLayout {
                        if !category.isEmpty {
                            UChip(text: category, style: .category)
                        }
                        if !value.isEmpty {
                            UChip(text: "\(value)\(unit.isEmpty ? "" : " \(unit)")", style: .value)
                        }
                        ForEach(parsedTags, id: \.self) { tag in
                            UChip(text: tag, style: .tag)
                        }
                        if !notes.isEmpty {
                            Text(notes)
                                .font(.uCaption)
                                .foregroundStyle(Color.secondaryLabel)
                                .lineLimit(1)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: category)
                    .animation(.easeInOut(duration: 0.2), value: value)
                    .animation(.easeInOut(duration: 0.2), value: tags)
                }

                // Fields
                Section("Parsed Fields") {
                    VStack(alignment: .leading, spacing: .spacing(.small)) {
                        fieldRow(label: "Category", placeholder: "e.g. Running, Sleep", text: $category)

                        HStack(spacing: .spacing(.medium)) {
                            fieldRow(label: "Value", placeholder: "e.g. 5", text: $value)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                            fieldRow(label: "Unit", placeholder: "e.g. km", text: $unit)
                        }

                        fieldRow(label: "Tags", placeholder: "comma separated", text: $tags)
                        fieldRow(label: "Notes", placeholder: "Optional notes...", text: $notes)
                    }
                    .padding(.vertical, .spacing(.xxSmall))
                }

                // Failed state hint
                if event.state == .failed {
                    Section {
                        HStack(spacing: .spacing(.small)) {
                            Image(systemName: Icons.failure)
                                .foregroundStyle(Color.negative)
                            Text("AI parsing failed. Edit manually or retry.")
                                .font(.uCallout)
                                .foregroundStyle(Color.secondaryLabel)
                        }
                    }
                }

                // Actions
                Section {
                    HStack(spacing: .spacing(.medium)) {
                        Button {
                            Task { await retryParsing() }
                        } label: {
                            Label("Retry Parse", systemImage: Icons.retry)
                                .font(.uBody)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.spacing(.small))
                                .background(Color.accentSoft, in: Capsule())
                                .foregroundStyle(Color.accent)
                        }
                        .buttonStyle(.plain)
                        .interactiveScale()
                        .disabled(event.state == .pending || isSaving || isDeleting)

                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: Icons.trash)
                                .font(.uBody)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.spacing(.small))
                                .background(Color.negativeSubtle, in: Capsule())
                                .foregroundStyle(Color.negative)
                        }
                        .buttonStyle(.plain)
                        .interactiveScale()
                        .disabled(isSaving || isDeleting)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Edit Event")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onFinished() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.bold)
                    .disabled(isSaving || isDeleting)
                }
            }
            .confirmationDialog(
                "Delete this event?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await deleteEvent() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. The event and its parsed data will be permanently removed.")
            }
        }
    }

    // MARK: - Helpers

    private var parsedTags: [String] {
        tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func fieldRow(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
            Text(label)
                .font(.uCaption2)
                .foregroundStyle(Color.secondaryLabel)
            TextField(placeholder, text: text)
                .premiumTextFieldStyle()
        }
    }

    // MARK: - Actions

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let payload = HabitParseResult(
            category: category.isEmpty ? nil : category.trimmingCharacters(in: .whitespacesAndNewlines),
            value: Double(value.replacingOccurrences(of: ",", with: ".")),
            unit: unit.isEmpty ? nil : unit.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: parsedTags.isEmpty ? nil : parsedTags,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await service.update(eventID: event.id, payload: payload)
            onFinished()
        } catch {}
    }

    private func retryParsing() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await service.retryParsing(eventID: event.id)
            onFinished()
        } catch {}
    }

    private func deleteEvent() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await service.delete(eventID: event.id)
            onFinished()
        } catch {}
    }
}
