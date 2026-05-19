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
    @Binding var expandedIngredients: Set<PersistentIdentifier>

    @State private var viewModel: IngredientListViewModel

    @AppStorage("ingredientListNoteDismissed") private var ingredientListNoteDismissed = false


    init(selectedFood: Binding<FoodItem?>, generator: IngredientGenerator, expandedIngredients: Binding<Set<PersistentIdentifier>>) {
        _selectedFood = selectedFood
        _expandedIngredients = expandedIngredients
        // modelContext is not available yet at init time; the VM is created with a
        // temporary context and swapped in onAppear via the environment.
        // Instead we pass the generator (which already holds a modelContext) and
        // defer full VM wiring to onAppear.
        _viewModel = State(initialValue: IngredientListViewModel(
            generator: generator,
            modelContext: generator.modelContext
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.isEditing {
                FoodGroupPicker(selectedGroup: $viewModel.selectedGroup, generatingGroup: viewModel.generator.generatingGroup)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }
            ScrollViewReader { proxy in
                List(selection: viewModel.isEditing ? $viewModel.selectedIDs : .constant(Set<PersistentIdentifier>())) {
                    if !viewModel.isEditing && !ingredientListNoteDismissed {
                        IngredientListNote(isDismissed: $ingredientListNoteDismissed)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 32, bottom: 8, trailing: 32))
                    }
                    if let foodGroup = viewModel.selectedFoodGroup {
                        let ingredients = viewModel.displayedIngredients
                        ForEach(
                            Array(ingredients.positionEnumerated()),
                            // Even though PersistentModel is already Identifiable
                            // we must manually specify the list identifier because
                            // of the enumerated tuple ^.
                            id: \.element.persistentModelID
                        ) { position, ingredient in
                            IngredientRow(
                                ingredient: ingredient,
                                isExpanded: expandedIngredients.contains(ingredient.persistentModelID),
                                isGenerating: viewModel.generatingVarieties.contains(ingredient.persistentModelID),
                                isEditMode: viewModel.isEditing,
                                onToggle: { viewModel.toggleExpanded(ingredient, expandedIngredients: &expandedIngredients) },
                                onSelect: { variety in
                                    viewModel.selectVariety(variety, ingredient: ingredient, group: foodGroup) { foodItem in
                                        selectedFood = foodItem
                                        dismiss()
                                    }
                                },
                                onHide: { viewModel.hideIngredient(ingredient, expandedIngredients: &expandedIngredients) },
                                onHideVariety: { variety in viewModel.hideVariety(variety) }
                            )
                            .listRowSeparator(position.isStart ? .hidden : .visible, edges: .top)
                            .listRowSeparator(position.isEnd ? .hidden : .visible, edges: .bottom)
                            .tag(ingredient.persistentModelID)
                        }
                        .onMove { source, destination in
                            viewModel.moveIngredients(from: source, to: destination)
                        }
                        if !viewModel.isEditing && viewModel.hasIngredients {
                            Button("Load More") {
                                Task { await viewModel.moreIngredients() }
                            }
                            .id("loadMoreButton")
                            .disabled(viewModel.isGenerating)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 12, leading: 32, bottom: 12, trailing: 32))
                        }
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, $viewModel.editMode)
                .onChange(of: viewModel.displayedIngredients.count) {
                    guard viewModel.isGenerating else {
                        return
                    }
                    withAnimation {
                        proxy.scrollTo("loadMoreButton", anchor: .bottom)
                    }
                }
            }
        }
        .navigationTitle("Ingredients")
        .onAppear {
            viewModel.refreshDisplayedIngredients()
        }
        .onChange(of: viewModel.selectedGroup) {
            viewModel.refreshDisplayedIngredients()
        }
        .onChange(of: viewModel.selectedFoodGroup?.ingredients?.count) {
            viewModel.refreshDisplayedIngredients()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.isEditing {
                    HStack {
                        Button("Alphabetical") {
                            viewModel.toggleAlphabetical()
                        }
                        .disabled(!viewModel.selectedIDs.isEmpty || viewModel.isAlphabetical)
                        Button("Hide Selected") {
                            viewModel.hideSelected(expandedIngredients: &expandedIngredients)
                        }
                        .disabled(viewModel.selectedIDs.isEmpty)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isEditing {
                    HStack {
                        Button("Done") {
                            withAnimation {
                                viewModel.isEditing = false
                                viewModel.selectedIDs = []
                            }
                        }
                    }
                } else {
                    HStack {
                        Button("Edit") {
                            viewModel.cancelCurrentGeneration(expandedIngredients: &expandedIngredients)
                            withAnimation {
                                viewModel.isEditing = true
                            }
                        }
                    }
                }
            }
        }
        .task(id: viewModel.selectedGroup) {
            guard !viewModel.hasIngredients else {
                // only auto-generate if there are none
                return
            }
            await viewModel.runIngredientGeneration()
        }
        .alert("Apple Intelligence", isPresented: .init(
            get: { viewModel.generatorError?.requiresAlert == true },
            set: { if !$0 { viewModel.generatorError = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.generatorError = nil }
        } message: {
            switch viewModel.generatorError {
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
                    .fontWeight(ingredient.isUsed ? .bold : .regular)
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
                        .fontWeight(ingredient.isUsed ? .bold : .regular)
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
                // Read the ingredient's streamed "about" description.
                // LEARNING: it's necessary to create this local variable
                // in order for SwiftUI to properly track this change.
                // e.g. if !ingredient.about.isEmpty does not work because
                // it doesn't allow SwiftUI to register the dependency
                // for observation and re-rendering.
                let about = ingredient.about
                if !about.isEmpty {
                    Text(about)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .padding(.leading, 16)
                }
                let visible = ingredient.varieties?.filter { !$0.isHidden } ?? []
                let varieties = visible.filter { $0.isUsed } + visible.filter { !$0.isUsed }
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
