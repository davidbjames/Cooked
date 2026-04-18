//
//  MealPlanView.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftUI
import SwiftData

struct MealPlanView: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss: DismissAction

    @State var mealPlan: MealPlan
    
    // @State private var selection = Set<PersistentIdentifier>()
    // @State private var isEditing = false
    // var isNew: Bool = false
    
    @State private var showNewCookingItemSheet = false
    @State private var navigateToRunTimer = false
    @State private var refreshId = UUID() // used to update times

    var body: some View {
        VStack {
            Form { // apparently a List under the hood
                // Meal plan name (optional)
                Section {
                    TextField("Optional name", text: Binding(
                        // Since the model is not observable, getting/setting
                        // its values is done with manual get/set here.
                        get: {
                            mealPlan.customName ?? ""
                        },
                        set: {
                            mealPlan.setCustomName($0.isEmpty ? nil : $0)
                        }
                    ))
                } header: {
                    Text("Name")
                }
                // Cooking items
                Section {
                    if let items = mealPlan.items, !items.isEmpty {
                        ForEach(items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.displayName)
                                    Text(item.relativeTimeDisplay)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .tag(item.persistentModelID)
                            .swipeActions(edge: .trailing, content: {
                                Button(role: .destructive) {
                                    modelContext.delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            })
                        }
                        // .onDelete { offsets in
                        //     for index in offsets {
                        //         mealPlan.items?.remove(at: index)
                        //     }
                        // }
                        // .onMove(perform: moveItems)
                    } else {
                        ContentUnavailableView(
                            "No cooking items",
                            systemImage: "fork.knife",
                            description: Text("Add items to this meal plan.")
                        )
                    }
                } header: {
                    Text("Cooking Items")
                } footer: {
                    HStack {
                        Button {
                            showNewCookingItemSheet = true
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                // Schedule preview
                if let items = mealPlan.items, !items.isEmpty {
                    Section {
                        // TODO: absolute time display should sometimes include seconds for short timers
                        if let event = mealPlan.createCompletionSchedule.first {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("\(event.title)")
                                        .bold()
                                    Spacer()
                                    Text("@")
                                    Text(event.absoluteTimeDisplay)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        ForEach(mealPlan.createCompletionSchedule.dropFirst(), id: \.self) { event in
                            VStack(alignment: .leading) {
                                Text("\(event.title)")
                                    .bold()
                                HStack {
                                    Spacer()
                                    Text("in")
                                    Text(event.relativeTimeDisplay)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                    Text("\(event.unitDisplay)  @")
                                    Text(event.absoluteTimeDisplay)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Schedule")
                            Spacer()
                            // TODO: get rid of refresh button
                            // TODO: automate the schedule every minute
                            // - move to separate view for performance
                            // - use content transition for numbers
                            Button {
                                refreshId = UUID() // forces update
                            } label: {
                                Label("Update", systemImage: "clock")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    }
                    .id(refreshId)
                }
            }
            // floating button bar that stays above the Form
            .safeAreaInset(edge: .bottom) {
                Button {
                    modelContext.insert(mealPlan)
                    navigateToRunTimer = true
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.title2.bold())
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 16)
                .background(.clear)
                .disabled(!mealPlan.hasCookingItems)
            }
        }
        .navigationDestination(isPresented: $navigateToRunTimer) {
            TimerRunView(mealPlan: mealPlan)
        }
        .navigationTitle(mealPlan.name)
        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button("Cancel") {
                    // no need to delete if it was never added to context (persisted)
//                    if isNew {
//                        modelContext.delete(mealPlan)
//                    }
//                    dismiss()
//                }
//            }
            if mealPlan.hasCookingItems {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(mealPlan)
                        dismiss()
                    }
                }
            }
#if os(iOS)
            if mealPlan.hasCookingItems {
                ToolbarItem {
                    EditButton()
                }
            }
#endif
        }
        .sheet(isPresented: $showNewCookingItemSheet) {
            NavigationStack {
                CookingItemView { newItem in
                    mealPlan.addCookingItem(newItem)
                }
            }
            .presentationDetents([.large])
        }
    }

//    private func moveItems(from source: IndexSet, to destination: Int) {
//        mealPlan.items?.move(fromOffsets: source, toOffset: destination)
//    }

}

