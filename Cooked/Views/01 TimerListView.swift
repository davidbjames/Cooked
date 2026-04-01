//
//  TimerListView.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftUI
import SwiftData

struct TimerListView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    /// Search text for timers or their contained foods
    @State 
    private var searchText: String = ""
    /// Only show search bar if there are a few timers
    private var presentSearchBar: Bool {
        _timers.count >= 3
    }

    /// Base query of timers. Don't use directly, use `filteredTimers` instead.
    @Query(sort: \CookingTimer.createdAt, order: .reverse)
    private var _timers: [CookingTimer]

    var filteredTimers: [CookingTimer] {
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // for this to work one must check the characters for white space and new lines
        guard !search.isEmpty else {
            return _timers
        }
        return _timers.filter { timer in
            if timer.name.lowercased().contains(search) {
                true
            } else {
                timer.items?.contains { item in
                    item.foodItem?.name.lowercased().contains(search) == true
                } == true
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(filteredTimers) { timer in
                NavigationLink {
                    TimerEditorView(timer: timer)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timer.name)
                            .font(.headline)
                        if let summary = timer.summary {
                            Text(summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .contextMenu { // long press
                    Button(role: .destructive) {
                        delete(timer)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(allowsFullSwipe: false) {
                    // Use swipeActions (18+) instead of onDelete on ForEach (13+).
                    // This reveals action buttons.
                    // Full swipe causes the first action to fire.
                    Button(role: .destructive) {
                        delete(timer)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            #if os(iOS)
            // iOS toolbar is on the List
            .navigationTitle("Timers")
            .toolbar { toolbar }
            #endif
            .if(presentSearchBar) { view in
                // note, though searchable has a isPresented param
                // it does not work reliably, even if the Binding (computed prop.)
                // provides a manual `get` callback equiv to presentSearchBar
                // which is why this uses the if condition
                view.searchable(
                    text: $searchText,
                    placement: .automatic,
                    prompt: Text("Search timers or foods")
                )
            }
        } content: { // these two are more applicable to regular horizontal size classes
            Label("Select a timer", systemImage: "timer")
        } detail: {
            Text("Select or create a timer")
                .foregroundStyle(.secondary)
        }
#if os(macOS)
        // macOS toolbar is on the split view
        .navigationTitle("Timers")
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        .toolbarRole(.editor)
        .toolbar { toolbar }
#endif
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                TimerEditorView(timer: CookingTimer(), isNew: true)
            } label: {
                Label("Add Timer", systemImage: "plus")
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Button(role: .destructive) {
                do {
                    try wipeAllData(context: modelContext)
                } catch {
                    print("Failed to wipe data: \(error)")
                }
            } label: {
                Label("Wipe Data", systemImage: "trash")
            }
            .tint(.red)
            .help("Delete all timers")
        }
#if os(iOS)
        ToolbarItem(placement: .secondaryAction) {
            EditButton()
        }
#endif
    }

    private func summary(for timer: CookingTimer) -> String {
        guard let items = timer.items else {
            return "Missing data"
        }
        let foods = items.compactMap { $0.foodItem?.name }
        if foods.isEmpty {
            return "No items"
        } else {
            return foods.joined(separator: ", ")
        }
    }

    private func delete(_ timer: CookingTimer) {
        modelContext.delete(timer)
        try? modelContext.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let timer = filteredTimers[index]
            delete(timer)
        }
    }
}


#Preview {
    let container = try! ModelContainer(
        for: FoodItem.self, FoodVariable.self, CookingItem.self, CookingTimer.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    // Seed mock data
    let chicken = FoodItem(name: "Chicken")
    let rice = FoodItem(name: "Rice")
    let pasta = FoodItem(name: "Pasta")
    let large = FoodVariable(name: "Large")
    let item1 = CookingItem(foodItem: chicken, cookingTimeSeconds: 45 * 60)
    let item2 = CookingItem(foodItem: rice, cookingTimeSeconds: 30 * 60)
    let item3 = CookingItem(foodItem: pasta, foodVariable: large, cookingTimeSeconds: 12 * 60)

    let timer1 = CookingTimer(items: [item1, item2])
    let timer2 = CookingTimer(items: [item3], customName: "Quick Lunch")

    context.insert(chicken)
    context.insert(rice)
    context.insert(pasta)
    context.insert(large)
    context.insert(item1)
    context.insert(item2)
    context.insert(item3)
    context.insert(timer1)
    context.insert(timer2)

    return TimerListView()
        .modelContainer(container)
}

