//
//  IngredientListView.swift
//  Cooked
//
//  Created by David James on 18/04/2026.
//

import SwiftUI
import SwiftData
import FoundationModels

// MARK: - IngredientListView

struct IngredientListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedFood: FoodItem?
    
    @State private var generator: IngredientGenerator
    @Binding var expandedIngredients: Set<PersistentIdentifier>
    @State private var generatingVarieties: Set<PersistentIdentifier> = []
    @State private var generatorError: GeneratorError?
    @State private var ingredientGenerationToken: Generator.GenerationToken
    @State private var varietyGenerationToken: Generator.GenerationToken?
    @State private var selectedGroup: FoodGroup.Group = .staple
    
    @State private var editMode: EditMode = .inactive
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var displayedIngredients: [Ingredient] = []
    
    private var isEditing: Bool {
        get { editMode.isEditing }
        nonmutating set { editMode = newValue ? .active : .inactive }
    }
    
    @AppStorage("ingredientListNoteDismissed") private var ingredientListNoteDismissed = false
    @AppStorage("ingredientOrderCustomised") private var ingredientOrderCustomised = false
    
    init(selectedFood: Binding<FoodItem?>, generator: IngredientGenerator, expandedIngredients: Binding<Set<PersistentIdentifier>>) {
        _selectedFood = selectedFood
        _generator = State(initialValue: generator)
        _expandedIngredients = expandedIngredients
        _ingredientGenerationToken = State(initialValue: generator.token)
    }
    
    private var selectedFoodGroup: FoodGroup? {
        generator.foodGroups.first { $0.group == selectedGroup }
    }
    
    private func sortedIngredients(for foodGroup: FoodGroup) -> [Ingredient] {
        let visible = foodGroup.ingredients?.filter { !$0.isHidden } ?? []
        if ingredientOrderCustomised {
            return visible.sorted { $0.sortOrder < $1.sortOrder }
        } else {
            return visible.sorted()
        }
    }
    
    private func refreshDisplayedIngredients() {
        guard let foodGroup = selectedFoodGroup else {
            displayedIngredients = []
            return
        }
        displayedIngredients = sortedIngredients(for: foodGroup)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !isEditing {
                FoodGroupPicker(selectedGroup: $selectedGroup, generatingGroup: generator.generatingGroup)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }
            List(selection: isEditing ? $selectedIDs : .constant(Set<PersistentIdentifier>())) {
                if !isEditing && !ingredientListNoteDismissed {
                    IngredientListNote(isDismissed: $ingredientListNoteDismissed)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 32, bottom: 8, trailing: 32))
                }
                if let foodGroup = selectedFoodGroup {
                    let ingredients = displayedIngredients
                    ForEach(Array(ingredients.enumerated()), id: \.element.persistentModelID) { index, ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            isExpanded: expandedIngredients.contains(ingredient.persistentModelID),
                            isGenerating: generatingVarieties.contains(ingredient.persistentModelID),
                            isEditMode: isEditing,
                            onToggle: { toggleExpanded(ingredient) },
                            onSelect: { variety in selectVariety(variety, ingredient: ingredient, group: foodGroup) },
                            onHide: { hideIngredient(ingredient) },
                            onHideVariety: { variety in hideVariety(variety) }
                        )
                        .listRowSeparator(index == 0 ? .hidden : .visible, edges: .top)
                        .listRowSeparator(index == ingredients.count - 1 ? .hidden : .visible, edges: .bottom)
                        .tag(ingredient.persistentModelID)
                    }
                    .onMove { source, destination in
                        moveIngredients(from: source, to: destination)
                    }
                }
            }
            .environment(\.editMode, $editMode)
        }
        .listStyle(.plain)
        .navigationTitle("Ingredients")
        .onAppear {
            refreshDisplayedIngredients()
        }
        .onChange(of: selectedGroup) {
            refreshDisplayedIngredients()
        }
        .onChange(of: selectedFoodGroup?.ingredients?.count) {
            refreshDisplayedIngredients()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack {
                        Button("Hide Selected") {
                            hideSelected()
                        }
                        .disabled(selectedIDs.isEmpty)
                        Button("Done") {
                            withAnimation {
                                isEditing = false
                                selectedIDs = []
                            }
                        }
                    }
                } else {
                    Button("Edit") {
                        cancelCurrentGeneration()
                        withAnimation {
                            isEditing = true
                        }
                    }
                }
            }
        }
        .task(id: selectedGroup) {
            let oldToken = generator.token
            generator.token = Generator.GenerationToken()
            ingredientGenerationToken = generator.token
            oldToken.isCancelled = true
            do {
                try await generator.generate(group: selectedGroup)
            } catch let error as GeneratorError {
                generatorError = error
            } catch {
                print(error)
            }
        }
        .alert("Apple Intelligence", isPresented: .init(
            get: { generatorError?.requiresAlert == true },
            set: { if !$0 { generatorError = nil } }
        )) {
            Button("OK", role: .cancel) { generatorError = nil }
        } message: {
            switch generatorError {
            case .availability(let unavailableReason):
                switch unavailableReason {
                case .appleIntelligenceNotEnabled:
                    Text("Apple Intelligence is not enabled. Please check it is enabled in Settings and try again.")
                case .deviceNotEligible:
                    Text("This device does not support Apple Intelligence. Varieties are not available.")
                case .modelNotReady:
                    Text("Apple Intelligence not ready. Please try again later.")
                @unknown default:
                    fatalError()
                }
            case .modelRefusal(let string):
                Text(string)
            case .cancelled:
                EmptyView() // this will never hit
            case nil:
                Text("Please try again later.")
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleExpanded(_ ingredient: Ingredient) {
        let id = ingredient.persistentModelID
        if expandedIngredients.contains(id) {
            expandedIngredients.remove(id)
        } else {
            expandedIngredients.insert(id)
            ingredientGenerationToken.isCancelled = true
            guard !generatingVarieties.contains(id) else {
                return
            }
            Task {
                do {
                    if varietyGenerationToken == nil {
                        varietyGenerationToken = .init()
                    }
                    let varietyGenerator = try VarietyGenerator(
                        ingredient: ingredient,
                        modelContext: modelContext,
                        token: varietyGenerationToken!
                    )
                    generatingVarieties.insert(id)
                    try await varietyGenerator.generate()
                    generatingVarieties.remove(id)
                } catch let error as GeneratorError {
                    generatingVarieties.remove(id)
                    generatorError = error
                } catch {
                    generatingVarieties.remove(id)
                }
            }
        }
    }
    
    private func hideIngredient(_ ingredient: Ingredient) {
        ingredient.visibilityState = IngredientVisibility.hidden.rawValue
        expandedIngredients.remove(ingredient.persistentModelID)
    }
    
    private func hideVariety(_ variety: Variety) {
        variety.visibilityState = IngredientVisibility.hidden.rawValue
    }
    
    private func hideSelected() {
        for ingredient in displayedIngredients where selectedIDs.contains(ingredient.persistentModelID) {
            hideIngredient(ingredient)
        }
        refreshDisplayedIngredients()
        withAnimation {
            selectedIDs = []
            isEditing = false
        }
    }
    
    private func moveIngredients(from source: IndexSet, to destination: Int) {
        displayedIngredients.move(fromOffsets: source, toOffset: destination)
        for (index, ingredient) in displayedIngredients.enumerated() {
            ingredient.sortOrder = index
        }
        ingredientOrderCustomised = true
    }
    
    private func cancelCurrentGeneration() {
        ingredientGenerationToken.isCancelled = true
        generator.token.isCancelled = true
        varietyGenerationToken?.isCancelled = true
        generatingVarieties.removeAll()
        expandedIngredients.removeAll()
    }
    
    private func selectVariety(_ variety: Variety?, ingredient: Ingredient, group: FoodGroup) {
        guard let varietyGenerationToken else {
            print("**** Variety generation cancellation token does not exist on variety selection")
            return
        }
        varietyGenerationToken.isCancelled = true
        generatingVarieties.removeAll()
        let foodItem = FoodItem(group: group, ingredient: ingredient, variety: variety)
        modelContext.insert(foodItem)
        selectedFood = foodItem
        dismiss()
    }
}

// MARK: - Ingredient List Note

private struct IngredientListNote: View {

    @Binding var isDismissed: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("Note: ingredients and varieties are generated from on-device AI. Results may vary. Tap an ingredient to see varieties. Tap variety to select. Swipe ingredients or hide varieties so they don't appear again. Edit to hide or re-order.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if false {
                // TBD: leave this off for now.
                // Possibly show it in edit mode only?
                Button {
                    withAnimation {
                        isDismissed = true
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss note")
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Food Group Picker

private struct FoodGroupPicker: View {
    
    @Binding var selectedGroup: FoodGroup.Group
    let generatingGroup: FoodGroup.Group?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(FoodGroup.Group.allCases, id: \.self) { group in
                Button {
                    selectedGroup = group
                } label: {
                    Text(group.title)
                        .font(.subheadline)
                        .fontWeight(selectedGroup == group ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selectedGroup == group ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.12)), in: Capsule())
                        .foregroundStyle(selectedGroup == group ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
                        .overlay(alignment: .bottom) {
                            ThinkingIndicator()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.bottom, 4)
                                .opacity(generatingGroup == group ? 1.0 : 0.0)
                        }
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: selectedGroup)
            }
        }
    }
}

// MARK: - Thinking Indicator

private struct ThinkingIndicator: View {
    
    @State private var phase: CGFloat = -1
    private let dashWidth: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .frame(width: dashWidth, height: 3)
                .offset(x: phase * (geo.size.width - dashWidth) / 2)
                .frame(maxWidth: .infinity, minHeight: 3, maxHeight: geo.size.height, alignment: .bottom)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        phase = 1
                    }
                }
        }
    }
}

struct FoodGroupPicker_Previews: PreviewProvider {
    @State static var selectedGroup: FoodGroup.Group = .staple
    @State static var generatingGroup: FoodGroup.Group? = .staple
    
    static var previews: some View {
        FoodGroupPicker(selectedGroup: $selectedGroup, generatingGroup: generatingGroup)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}


// MARK: - Food Chip (ingredient or variety)

private struct IngredientChip<Variation: IngredientVariation>: View {
    let ingredient: Variation
    let onSelect: () -> Void
    var onHide: (() -> Void)? = nil

    private var isIngredient: Bool { ingredient is Ingredient }

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onSelect) {
                Text(ingredient.name.capitalized(with: .current))
                    .font(.subheadline)
            }
            if !isIngredient, let onHide {
                Button(action: onHide) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .font(.caption)
                }
                .accessibilityLabel("Hide \(ingredient.name.capitalized(with: .current))")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isIngredient ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.12)), in: Capsule())
        .foregroundStyle(isIngredient ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
        .buttonStyle(.plain)
        .accessibilityLabel(ingredient.name.capitalized(with: .current))
    }
}


// MARK: - Ingredient Row

private struct IngredientRow: View {
    let ingredient: Ingredient
    let isExpanded: Bool
    let isGenerating: Bool
    let isEditMode: Bool
    let onToggle: () -> Void
    let onSelect: (Variety?) -> Void
    let onHide: () -> Void
    let onHideVariety: (Variety) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ingredient header — tapping expands/collapses varieties (normal mode only)
            Button(action: isEditMode ? {} : onToggle) {
                HStack {
                    Text(ingredient.name.capitalized(with: .current))
                        .foregroundStyle(.primary)
                    Spacer()
                    if !isEditMode {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isEditMode
                    ? ingredient.name.capitalized(with: .current)
                    : isExpanded
                        ? "Collapse \(ingredient.name.capitalized(with: .current))"
                        : "Expand \(ingredient.name.capitalized(with: .current))"
            )
            .accessibilityAddTraits(.isButton)

            if !isEditMode && isExpanded {
                if !ingredient.about.isEmpty {
                    Text(ingredient.about)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .padding(.leading, 16)
                }
                // Unlike ingredients, varieties are not sorted so the
                // generating items remain stable for selection.
                let varieties = ingredient.varieties?.filter { !$0.isHidden } ?? []
                if !varieties.isEmpty || isGenerating {
                    FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                        IngredientChip(ingredient: ingredient) {
                            onSelect(nil)
                        }
                        ForEach(varieties, id: \.persistentModelID) { variety in
                            IngredientChip(ingredient: variety) {
                                onSelect(variety)
                            } onHide: {
                                onHideVariety(variety)
                            }
                        }
                        if isGenerating {
                            ProgressView()
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, isExpanded && !isEditMode ? 10 : 2)
        .listRowInsets(EdgeInsets(top: 0, leading: 32, bottom: 0, trailing: 32))
        .swipeActions(edge: .trailing) {
            if !isEditMode {
                Button(role: .destructive, action: onHide) {
                    Label("Hide", systemImage: "eye.slash")
                }
            }
        }
    }
}

struct IngredientRow_Previews: PreviewProvider {
    static var previews: some View {
        IngredientRow(
            ingredient: Ingredient(name: "Potato", isRegional: false),
            isExpanded: true,
            isGenerating: false,
            isEditMode: false,
            onToggle: {},
            onSelect: { _ in },
            onHide: {},
            onHideVariety: { _ in }
        )
        .previewLayout(.sizeThatFits)
    }
}
