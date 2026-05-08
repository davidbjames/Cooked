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
    
    init(selectedFood: Binding<FoodItem?>, generator: IngredientGenerator, expandedIngredients: Binding<Set<PersistentIdentifier>>) {
        _selectedFood = selectedFood
        _generator = State(initialValue: generator)
        _expandedIngredients = expandedIngredients
        _ingredientGenerationToken = State(initialValue: generator.token)
    }
    
    private var selectedFoodGroup: FoodGroup? {
        generator.foodGroups.first { $0.group == selectedGroup }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            FoodGroupPicker(selectedGroup: $selectedGroup, generatingGroup: generator.generatingGroup)
                .padding(.horizontal)
                .padding(.vertical, 10)
            List {
                if let foodGroup = selectedFoodGroup {
                    ForEach(foodGroup.ingredients?.sorted() ?? [], id: \.persistentModelID) { ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            isExpanded: expandedIngredients.contains(ingredient.persistentModelID),
                            isGenerating: generatingVarieties.contains(ingredient.persistentModelID),
                            onToggle: { toggleExpanded(ingredient) },
                            onSelect: { variety in selectVariety(variety, ingredient: ingredient, group: foodGroup) }
                        )
                    }
                }
            }
        }
        .navigationTitle("Ingredients")
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

    private var isIngredient: Bool { ingredient is Ingredient }

    var body: some View {
        Button(action: onSelect) {
            Text(ingredient.name.capitalized(with: .current))
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isIngredient ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.12)), in: Capsule())
                .foregroundStyle(isIngredient ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ingredient.name.capitalized(with: .current))
    }
}


// MARK: - Ingredient Row

private struct IngredientRow: View {
    let ingredient: Ingredient
    let isExpanded: Bool
    let isGenerating: Bool
    let onToggle: () -> Void
    let onSelect: (Variety?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ingredient header — tapping expands/collapses varieties
            Button(action: onToggle) {
                HStack {
                    Text(ingredient.name.capitalized(with: .current))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .contentShape(Rectangle()) // entire row is tappable to expand ingredient
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isExpanded
                    ? "Collapse \(ingredient.name.capitalized(with: .current))"
                    : "Expand \(ingredient.name.capitalized(with: .current))"
            )
            .accessibilityAddTraits(.isButton)

            if isExpanded {
                // Unlike ingredients, varieties are not sorted so the
                // generating items remain stable for selection.
                let varieties = ingredient.varieties ?? []
                if !varieties.isEmpty || isGenerating {
                    FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                        IngredientChip(ingredient: ingredient) {
                            onSelect(nil)
                        }
                        ForEach(varieties, id: \.persistentModelID) { variety in
                            IngredientChip(ingredient: variety) {
                                onSelect(variety)
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
        .padding(.vertical, 2)
    }
}


