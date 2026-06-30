//
//  CategoryManagementView.swift
//  uniks
//
//  Full category management: list, rename, merge, colors, custom create, delete.
//

import SwiftUI
import SwiftData

@MainActor
struct CategoryManagementView: View {
    @Query(sort: \HabitEvent.createdAt, order: .reverse) private var events: [HabitEvent]
    @Query private var customCategories: [CustomCategory]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: String?
    @State private var isShowingRename = false
    @State private var isShowingMerge = false
    @State private var isShowingCreate = false
    @State private var renameText = ""
    @State private var mergeTarget = ""

    var body: some View {
        NavigationStack {
            List {
                // Custom categories section
                if !customCategories.isEmpty {
                    Section("Custom Categories") {
                        ForEach(customCategories) { category in
                            HStack(spacing: .spacing(.small)) {
                                Circle()
                                    .fill(CategoryColorStore.palette[category.colorIndex % CategoryColorStore.palette.count])
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                                    .font(.uBody)
                                Spacer()
                                Text(category.keywordList.joined(separator: ", "))
                                    .font(.uCaption2)
                                    .foregroundStyle(Color.secondaryLabel)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                // Detected categories from events
                Section("Detected Categories") {
                    ForEach(sortedCategories, id: \.name) { cat in
                        HStack(spacing: .spacing(.small)) {
                            Circle()
                                .fill(Color.categoryColor(for: cat.name))
                                .frame(width: 12, height: 12)
                            Text(cat.name)
                                .font(.uBody)
                            Spacer()
                            Text("\(cat.count) events")
                                .font(.uCaption)
                                .foregroundStyle(Color.secondaryLabel)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = cat.name
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Rename") {
                                selectedCategory = cat.name
                                renameText = cat.name
                                isShowingRename = true
                            }
                            .tint(Color.accent)

                            Button("Merge") {
                                selectedCategory = cat.name
                                isShowingMerge = true
                            }
                            .tint(Color.warning)
                        }
                    }
                }

                // Color palette section
                Section("Color Palette") {
                    Text("Tap a category above to customize its color.")
                        .font(.uCallout)
                        .foregroundStyle(Color.secondaryLabel)

                    if let selected = selectedCategory {
                        VStack(alignment: .leading, spacing: .spacing(.small)) {
                            Text("Color for \(selected)")
                                .font(.uCaption)
                                .foregroundStyle(Color.secondaryLabel)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: .spacing(.small)) {
                                ForEach(0..<CategoryColorStore.palette.count, id: \.self) { index in
                                    Circle()
                                        .fill(CategoryColorStore.palette[index])
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primaryLabel, lineWidth: 2)
                                                .opacity(CategoryColorStore.colorIndex(for: selected) == index ? 1 : 0)
                                        )
                                        .onTapGesture {
                                            CategoryColorStore.setColor(index: index, for: selected)
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingCreate = true
                    } label: {
                        Image(systemName: Icons.add)
                    }
                    .accessibilityLabel("Create custom category")
                }
            }
            .alert("Rename Category", isPresented: $isShowingRename) {
                TextField("New name", text: $renameText)
                Button("Rename") { renameCategory() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Merge Into", isPresented: $isShowingMerge) {
                TextField("Target category", text: $mergeTarget)
                Button("Merge") { mergeCategory() }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $isShowingCreate) {
                CreateCustomCategorySheet()
            }
        }
    }

    // MARK: - Computed

    private struct CategoryCount: Identifiable {
        let name: String
        let count: Int
        var id: String { name }
    }

    private var sortedCategories: [CategoryCount] {
        var counts: [String: Int] = [:]
        for event in events {
            if let cat = event.parsedPayload()?.category,
               !cat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let normalized = cat.capitalized
                counts[normalized, default: 0] += 1
            }
        }
        return counts.map { CategoryCount(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Actions

    @MainActor
    private func renameCategory() {
        guard let old = selectedCategory, !renameText.isEmpty else { return }
        let modelContext = events.first?.modelContext
        for event in events {
            guard var payload = event.parsedPayload(),
                  payload.category?.lowercased() == old.lowercased() else { continue }
            payload.category = renameText.capitalized
            event.setParsedPayload(payload)
        }
        try? modelContext?.save()
    }

    @MainActor
    private func mergeCategory() {
        guard let source = selectedCategory, !mergeTarget.isEmpty else { return }
        let modelContext = events.first?.modelContext
        for event in events {
            guard var payload = event.parsedPayload(),
                  payload.category?.lowercased() == source.lowercased() else { continue }
            payload.category = mergeTarget.capitalized
            event.setParsedPayload(payload)
        }
        try? modelContext?.save()
    }
}

// MARK: - Create Custom Category Sheet

private struct CreateCustomCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var keywords = ""
    @State private var colorIndex = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    TextField("Name", text: $name)
                        .premiumTextFieldStyle()
                    TextField("Keywords (comma separated)", text: $keywords)
                        .premiumTextFieldStyle()
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: .spacing(.small)) {
                        ForEach(0..<CategoryColorStore.palette.count, id: \.self) { index in
                            Circle()
                                .fill(CategoryColorStore.palette[index])
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primaryLabel, lineWidth: 2)
                                        .opacity(colorIndex == index ? 1 : 0)
                                )
                                .onTapGesture { colorIndex = index }
                        }
                    }
                }
            }
            .navigationTitle("New Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let keywordList = keywords.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let category = CustomCategory(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).capitalized,
            keywords: keywordList,
            colorIndex: colorIndex
        )
        modelContext.insert(category)
        try? modelContext.save()
        dismiss()
    }
}
