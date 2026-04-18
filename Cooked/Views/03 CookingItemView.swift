//
//  CookingItemView.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftUI
import SwiftData
import FoundationModels

struct CookingItemView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Callback to pass the created CookingItem back to the caller
    var onSave: (CookingItem) -> Void

    @State private var selectedFood: FoodItem?
    
    // Food variable selection/creation
    @Query(sort: \FoodVariable.name) private var variables: [FoodVariable]
    @State private var variableText: String = ""
    @State private var selectedVariable: FoodVariable?

    // Time input
    @State private var minutes: String = ""
    @State private var seconds: String = ""

    var body: some View {
        Form {
            Section(header: Text("Ingredient")) {
                NavigationLink {
                    FoodListView(selectedFood: $selectedFood)
                } label: {
                    HStack {
                        Text("Select")
                        Spacer()
                        Text(selectedFood?.name ?? "None")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(header: Text("Food Variable (optional)")) {
                TextField("e.g. 1.7 kg, large", text: $variableText)
                    .onSubmit {
                        pickOrCreateVariableIfNeeded()
                    }
                if !variableText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(suggestedVariables, id: \.persistentModelID) { variable in
                                Button {
                                    variableText = variable.name
                                    selectedVariable = variable
                                } label: {
                                    Text(variable.name)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }

            Section(header: Text("Cooking Time")) {
                HStack {
                    TextField("Minutes", text: $minutes)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                    Text("min")
                    TextField("Seconds", text: $seconds)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                    Text("sec")
                }
            }

            Section {
                Button {
                    save()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSave)
            }
        }
        .navigationTitle("Add Item")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onChange(of: variableText) { _, newValue in
            // Clear selectedVariable if text diverges from its name
            if let selected = selectedVariable, selected.name.caseInsensitiveCompare(newValue) != .orderedSame {
                selectedVariable = nil
            }
        }
    }

    private var suggestedVariables: [FoodVariable] {
        let q = variableText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            return Array(variables.prefix(8))
        } else {
            let lower = q.lowercased()
            return variables.filter { $0.name.lowercased().contains(lower) }.prefix(12).map { $0 }
        }
    }

    private var canSave: Bool {
        guard let _ = selectedFood else { return false }
        let totalSeconds = parsedSeconds()
        return totalSeconds > 0
    }

    private func pickOrCreateVariableIfNeeded() {
        let name = variableText.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            selectedVariable = nil
            return
        }
        if let existing = variables.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            selectedVariable = existing
        } else {
            let new = FoodVariable(name: name)
            modelContext.insert(new)
            selectedVariable = new
        }
    }

    private func parsedSeconds() -> Int {
        let m = Int(minutes) ?? 0
        let s = Int(seconds) ?? 0
        return max(0, m * 60 + s)
    }

    private func save() {
        guard let food = selectedFood else { return }
        pickOrCreateVariableIfNeeded()
        let totalSeconds = parsedSeconds()
        guard totalSeconds > 0 else { return }

        let item = CookingItem(food: food, variable: selectedVariable, minutes: Double(totalSeconds) / 60)
        modelContext.insert(item)
        onSave(item)
        dismiss()
    }
}

