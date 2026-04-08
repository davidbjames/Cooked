//
//  TimerListView.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftUI
import SwiftData

struct TimerListView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    #if os(iOS)
    @Environment(\.editMode) private var editMode
    #endif
    
    /// Search text for timers or their contained foods
    @State private var searchText: String = ""
    
    /// Only show search bar if there are a few timers
    @State private var presentSearchBar: Bool = false

    /// Base query of timers. Don't use directly, use `filteredTimers` instead.
    @Query(sort: \CookingTimer.createdAt, order: .reverse)
    private var _timers: [CookingTimer]
    
    // TODO: order these timers by the most recently used
    
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
                        timer.delete(in: modelContext)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(allowsFullSwipe: false) {
                    // Use swipeActions (18+) instead of onDelete on ForEach (13+).
                    // This reveals action buttons.
                    // Full swipe causes the first action to fire.
                    Button(role: .destructive) {
                        timer.delete(in: modelContext)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                // .listRowBackground(Rectangle().fill(LinearGradient(...
//                .onAppear {
//                    for timer in filteredTimers {
//                        guard let items = timer.items else {
//                            continue
//                        }
//                        print("-----")
//                        print(timer.name)
//                        for item in items {
//                            guard let innerTimers = item.cookingTimers else {
//                                continue
//                            }
//                            print("    ", item.displayName)
//                            for innerTimer in innerTimers {
//                                print("        ", innerTimer.name)
//                            }
//                        }
//                    }
//                }
            }
            .scrollContentBackground(.hidden)
#if os(macOS)
            .searchable(
                text: $searchText,
                // this only pertains to search bar *focus*, not visibility
                // isPresented: $presentSearchBar,
                placement: .automatic,
                prompt: Text("Search timers or foods")
            )
#else
            // iOS toolbar is on the List *
            .navigationTitle("Meal Plans")
            .toolbar { toolbar }
            // custom search bar only on iOS devices because
            // it doesn't work well with split view navigation on macOS
            // and to control visibility
            .if(presentSearchBar) { view in
                    view.safeAreaInset(edge: .bottom) {
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("Search timers or foods", text: $searchText)
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(8)
                            .background(.regularMaterial, in: Capsule())
                            
                            NavigationLink {
                                TimerEditorView(timer: CookingTimer(), isNew: true)
                            } label: {
                                Image(systemName: "plus")
                                // .foregroundStyle(Color.secondaryColor)
                                    .padding(10)
                                    .background(.regularMaterial, in: Circle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
            }
#endif
        } content: { // these two are more applicable to regular horizontal size classes
            Label("Select a meal plan", systemImage: "timer")
        } detail: {
            Text("Select or create a meal plan")
                .foregroundStyle(.secondary)
        }
#if os(macOS)
        // macOS toolbar is on the split view *
        .navigationTitle("Meal Plans")
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        .toolbarRole(.editor)
        .toolbar { toolbar }
#endif
        // imperative state changes
        .onChange(of: _timers.count) { _, newCount in
            presentSearchBar = newCount >= 3
        }
        .onAppear {
            presentSearchBar = _timers.count >= 3
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                TimerEditorView(timer: CookingTimer(), isNew: true)
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("New")
                    // .fontWeight(.heavy)
                    // .tint(Color.primaryColor) // does not work here
                }
            }
            // .tint(Color.secondaryColor)
        }
        
#if os(iOS)
        ToolbarItem(placement: .primaryAction) {
            EditButton()
        }
#endif
#if DEBUG
        ToolbarItemGroup(placement: .destructiveAction) {
            //            ToolbarItem(placement: .secondaryAction) {
            Button(role: .destructive) {
                do {
                    try DataHelpers.resetMockData(context: modelContext)
                } catch {
                    print("Failed to reset data: \(error)")
                }
            } label: {
                Label("Reset Mock Data", systemImage: "arrow.counterclockwise")
            }
            .help("Reset test data")
            //            }
            //            ToolbarItem(placement: .secondaryAction) {
            Button(role: .destructive) {
                do {
                    try DataHelpers.wipeAllData(context: modelContext)
                } catch {
                    print("Failed to wipe data: \(error)")
                }
            } label: {
                Label("Wipe Data", systemImage: "trash")
            }
            .tint(.red)
            .help("Delete all timers")
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
    let item1 = CookingItem(food: chicken, minutes: 45)
    let item2 = CookingItem(food: rice, minutes: 30)
    let item3 = CookingItem(food: pasta, variable: large, minutes: 12)
    
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

