//
//  EventEditView.swift
//  uniks
//
//  Sheet for correcting AI-parsed fields or retrying parsing.
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
                Section {
                    VStack(alignment: .leading, spacing: .spacing(.xxSmall)) {
                        Text("Raw Input")
                            .font(.uCaption)
                            .foregroundStyle(Color.secondaryLabel)
                            .textCase(.uppercase)
                            .tracking(1.0)
                        
                        Text(event.rawInput)
                            .font(.uBody)
                            .foregroundStyle(Color.primaryLabel)
                    }
                    .padding(.vertical, .spacing(.xxSmall))
                }

                Section("Parsed Fields") {
                    VStack(alignment: .leading, spacing: .spacing(.small)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Category")
                                .font(.uCaption2)
                                .foregroundStyle(Color.secondaryLabel)
                            TextField("e.g. Running, Sleep", text: $category)
                                .premiumTextFieldStyle()
                        }
                        
                        HStack(spacing: .spacing(.medium)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Value")
                                    .font(.uCaption2)
                                    .foregroundStyle(Color.secondaryLabel)
                                TextField("e.g. 5, 8.5", text: $value)
                                    #if os(iOS)
                                    .keyboardType(.decimalPad)
                                    #endif
                                    .premiumTextFieldStyle()
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Unit")
                                    .font(.uCaption2)
                                    .foregroundStyle(Color.secondaryLabel)
                                TextField("e.g. km, hrs", text: $unit)
                                    .premiumTextFieldStyle()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tags")
                                .font(.uCaption2)
                                .foregroundStyle(Color.secondaryLabel)
                            TextField("Tags (comma separated)", text: $tags)
                                .premiumTextFieldStyle()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.uCaption2)
                                .foregroundStyle(Color.secondaryLabel)
                            TextField("Optional notes...", text: $notes, axis: .vertical)
                                .premiumTextFieldStyle()
                                .lineLimit(2...4)
                        }
                    }
                    .padding(.vertical, .spacing(.xxSmall))
                }

                if event.state == .failed {
                    Section {
                        HStack(spacing: .spacing(.small)) {
                            Image(systemName: Icons.failure)
                                .foregroundStyle(Color.negative)
                            Text("AI Parsing failed. You can edit the fields manually or retry below.")
                                .font(.uCallout)
                                .foregroundStyle(Color.secondaryLabel)
                        }
                        .padding(.vertical, .spacing(.xxSmall))
                    }
                }

                Section {
                    HStack(spacing: .spacing(.medium)) {
                        Button {
                            Task { await retryParsing() }
                        } label: {
                            HStack {
                                Image(systemName: Icons.retry)
                                Text("Retry Parse")
                            }
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.spacing(.small))
                            .background(Color.accentColor.opacity(0.1), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .interactiveScale()
                        .disabled(event.state == .pending || isSaving || isDeleting)

                        Button {
                            Task { await deleteEvent() }
                        } label: {
                            HStack {
                                Image(systemName: Icons.trash)
                                Text("Delete")
                            }
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.spacing(.small))
                            .background(Color.negative.opacity(0.08), in: Capsule())
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
                    Button("Cancel") {
                        onFinished()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || isDeleting)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let tagList = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let payload = HabitParseResult(
            category: trimmedCategory.isEmpty ? nil : trimmedCategory,
            value: Double(value.replacingOccurrences(of: ",", with: ".")),
            unit: trimmedUnit.isEmpty ? nil : trimmedUnit,
            tags: tagList.isEmpty ? nil : tagList,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )

        do {
            try await service.update(eventID: event.id, payload: payload)
            onFinished()
        } catch {
            // Silent failure; the sheet stays open so the user can retry.
        }
    }

    private func retryParsing() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await service.retryParsing(eventID: event.id)
            onFinished()
        } catch {
            // Silent failure; the user can retry again.
        }
    }

    private func deleteEvent() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await service.delete(eventID: event.id)
            onFinished()
        } catch {
            // Silent failure; the sheet stays open so the user can retry.
        }
    }
}

struct PremiumTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .rounded))
            .padding(.horizontal, .spacing(.small))
            .padding(.vertical, .spacing(.xSmall))
            .background(Color.tertiaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: .radius(.small)))
            .overlay(
                RoundedRectangle(cornerRadius: .radius(.small))
                    .stroke(Color.separator.opacity(0.3), lineWidth: 0.5)
            )
    }
}

extension View {
    func premiumTextFieldStyle() -> some View {
        modifier(PremiumTextFieldModifier())
    }
}
