//
//  TimerEditorView.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftUI
import SwiftData

struct TimerEditorView: View {
    
    @Environment(\.modelContext)
    private var modelContext: ModelContext
    
    @Environment(\.dismiss)
    private var dismiss: DismissAction

    @State private var selection = Set<PersistentIdentifier>()
    @State private var showingNewItemSheet = false
    @State private var navigateToRun = false
    
    @State private var isEditing = false

    @State var timer: CookingTimer
    var isNew: Bool = false
    
    @State private var refreshId = UUID() // used to update times

    var body: some View {
        VStack {
            Form { // apparently a List under the hood
                // Timer name (optional)
                Section {
                    TextField("Optional name", text: Binding(
                        // Since the model is not observable, getting/setting
                        // its values is done with manual get/set here.
                        get: {
                            timer.customName ?? ""
                        },
                        set: {
                            timer.customName = $0.isEmpty ? nil : $0
                        }
                    ))
                } header: {
                    Text("Name")
                }
                // Cooking items
                Section {
                    if let items = timer.items, !items.isEmpty {
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
                                    item.delete(in: modelContext)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            })
                        }
//                            .onDelete { offsets in
//                                for index in offsets {
//                                    timer.items?.remove(at: index)
//                                }
//                            }
//                            .onMove(perform: moveItems)
                    } else {
                        ContentUnavailableView(
                            "No cooking items",
                            systemImage: "fork.knife",
                            description: Text("Add items to this timer.")
                        )
                    }
                } header: {
                    Text("Cooking Items")
                } footer: {
                    HStack {
                        Button {
                            showingNewItemSheet = true
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                // Schedule preview
                if let items = timer.items, !items.isEmpty {
                    Section {
                        // TODO: absolute time display should sometimes include seconds for short timers
                        if let event = timer.createCompletionSchedule.first {
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
                        ForEach(timer.createCompletionSchedule.dropFirst(), id: \.self) { event in
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
                    modelContext.insert(timer)
                    try? modelContext.save()
                    navigateToRun = true
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.title2.bold())
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 16)
                .background(.clear)
                .disabled(!timer.hasCookingItems)
            }
        }
        .navigationDestination(isPresented: $navigateToRun) {
            TimerRunView(timer: timer)
        }
        .navigationTitle(timer.name)
        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button("Cancel") {
                    // no need to delete if it was never added to context (persisted)
//                    if isNew {
//                        modelContext.delete(timer)
//                    }
//                    dismiss()
//                }
//            }
            if timer.hasCookingItems {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(timer)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
#if os(iOS)
            if timer.hasCookingItems {
                ToolbarItem {
                    EditButton()
                }
            }
#endif
        }
        .sheet(isPresented: $showingNewItemSheet) {
            NavigationStack {
                CookingItemView { newItem in
                    timer.items?.append(newItem)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        timer.items?.move(fromOffsets: source, toOffset: destination)
    }

}

#Preview {
    let container = try! ModelContainer(
        for: FoodItem.self, FoodVariable.self, CookingItem.self, CookingTimer.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    
    let chicken = FoodItem(name: "Chicken")
    let steak = FoodItem(name: "Steak")
    let weight = FoodVariable(name: "1.2 kg")
    let doneness = FoodVariable(name: "Medium-rare")

    let item1 = CookingItem(food: chicken, variable: weight, minutes: 50)
    let item2 = CookingItem(food: steak, variable: doneness, minutes: 12)

    let timer = CookingTimer(items: [item1, item2], customName: "Sunday Dinner")

    context.insert(chicken)
    context.insert(steak)
    context.insert(weight)
    context.insert(doneness)
    context.insert(item1)
    context.insert(item2)
    context.insert(timer)

    return NavigationStack {
        TimerEditorView(timer: timer)
    }
    .modelContainer(container)
}

#Preview("Empty Timer") {
    let container = try! ModelContainer(
        for: FoodItem.self, FoodVariable.self, CookingItem.self, CookingTimer.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return NavigationStack {
        TimerEditorView(timer: CookingTimer(), isNew: true)
    }
    .modelContainer(container)
}

