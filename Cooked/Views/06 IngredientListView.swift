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
    @State private var expandedIngredients: Set<PersistentIdentifier> = []
    @State private var generatingVarieties: Set<PersistentIdentifier> = []
    @State private var generatorError: SystemLanguageModel.Availability?
    
    init(selectedFood: Binding<FoodItem?>, generator: IngredientGenerator) {
        _selectedFood = selectedFood
        _generator = State(initialValue: generator)
    }
    
    var body: some View {
        List {
            ForEach(generator.foodGroups, id: \.persistentModelID) { foodGroup in
                Section(header: Text(foodGroup.group.title)) {
                    ForEach(foodGroup.ingredients?.sorted() ?? [], id: \.persistentModelID) { ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            isExpanded: expandedIngredients.contains(ingredient.persistentModelID),
                            isGenerating: generatingVarieties.contains(ingredient.persistentModelID),
                            onToggle: { toggleExpanded(ingredient) },
                            onSelectVariety: { variety in selectVariety(variety, ingredient: ingredient, group: foodGroup) }
                        )
                    }
                }
            }
        }
        .navigationTitle("Ingredients")
        .task {
            await generator.generateIngredients()
        }
        .alert("Apple Intelligence", isPresented: .init(
            get: { generatorError?.isAvailable == false },
            set: { if !$0 { generatorError = nil } }
        )) {
            Button("OK", role: .cancel) { generatorError = nil }
        } message: {
            if case let .unavailable(error) = generatorError {
                switch error {
                case .appleIntelligenceNotEnabled:
                    Text("Apple Intelligence is not enabled. Please check it is enabled in Settings and try again.")
                case .deviceNotEligible:
                    Text("This device does not support Apple Intelligence. Varieties are not available.")
                case .modelNotReady:
                    Text("Apple Intelligence not ready. Please try again later.")
                @unknown default:
                    fatalError()
                }
            } else {
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
            // Only generate varieties if none exist yet and not already generating
            if /*ingredient.varieties?.isEmpty != false, */!generatingVarieties.contains(id) {
                Task {
                    do {
                        let varietyGenerator = try VarietyGenerator(
                            ingredient: ingredient,
                            modelContext: modelContext
                        )
                        generatingVarieties.insert(id)
                        await varietyGenerator.generateVarieties()
                        generatingVarieties.remove(id)
                    } catch let error as GeneratorError {
                        generatingVarieties.remove(id)
                        generatorError = .unavailable(error.reason)
                    } catch {
                        generatingVarieties.remove(id)
                        generatorError = .unavailable(.appleIntelligenceNotEnabled)
                    }
                }
            }
        }
    }
    
    private func selectVariety(_ variety: Variety, ingredient: Ingredient, group: FoodGroup) {
        let foodItem = FoodItem(group: group, ingredient: ingredient, variety: variety)
        modelContext.insert(foodItem)
        selectedFood = foodItem
        dismiss()
    }
}

// MARK: - Flow Layout

/// A simple wrapping flow layout that arranges children left-to-right,
/// wrapping onto new rows as needed.
private struct FlowLayout: Layout {

    var horizontalSpacing: CGFloat = 6
    var verticalSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + verticalSpacing
                x = 0
                rowHeight = 0
            }
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
        y += rowHeight
        return CGSize(width: maxWidth, height: y)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + verticalSpacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
        _ = maxWidth // suppress warning
    }
}

// MARK: - Variety Chip

private struct VarietyChip: View {
    let variety: Variety
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(variety.name.capitalized(with: .current))
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.tint.opacity(0.12), in: Capsule())
                .foregroundStyle(.tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(variety.name.capitalized(with: .current))
    }
}


// MARK: - Ingredient Row

private struct IngredientRow: View {
    let ingredient: Ingredient
    let isExpanded: Bool
    let isGenerating: Bool
    let onToggle: () -> Void
    let onSelectVariety: (Variety) -> Void

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
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isExpanded
                    ? "Collapse \(ingredient.name.capitalized(with: .current))"
                    : "Expand \(ingredient.name.capitalized(with: .current))"
            )
            .accessibilityAddTraits(.isButton)

            if isExpanded {
                if isGenerating {
                    // Show spinner while varieties are being generated
                    HStack {
                        ProgressView()
                            .padding(.leading, 16)
                        Spacer()
                    }
                } else if let _varieties = ingredient.varieties, !_varieties.isEmpty {
                    let varieties = _varieties.sorted()
                    // Variety chips
                    FlowLayout(horizontalSpacing: 6, verticalSpacing: 6)
                        .callAsFunction {
                            ForEach(varieties, id: \.persistentModelID) { variety in
                                VarietyChip(variety: variety) {
                                    onSelectVariety(variety)
                                }
                            }
                        }
                        .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, 2)
    }
}


