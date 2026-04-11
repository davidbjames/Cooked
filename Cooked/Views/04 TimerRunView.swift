//
//  TimerRunView.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftUI
import SwiftData

struct TimerRunView: View {
    var mealPlan: MealPlan

    var body: some View {
        List {
            Section {
                HStack {
                    Text(mealPlan.name)
                        .font(.title2.bold())
                    Spacer()
                }
                HStack {
                    Text("Total")
                    Spacer()
                    Text(timeString(seconds: mealPlan.timeInSeconds))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Rings")) {
                ForEach(mealPlan.createCompletionSchedule, id: \.self) { event in
                    HStack {
                        if event.isFinal {
                            Text("Finish")
                        } else {
                            let names = event.startingItems.map { $0.displayName }.joined(separator: ", ")
                            Text("Start: \(names)")
                        }
                        Spacer()
                        Text(timeString(seconds: event.timeInSeconds))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Timer")
    }

    private func timeString(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: FoodItem.self, FoodVariable.self, CookingItem.self, MealPlan.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext

    let chicken = FoodItem(name: "Chicken")
    let rice = FoodItem(name: "Rice")
    let item1 = CookingItem(food: chicken, minutes: 45)
    let item2 = CookingItem(food: rice, minutes: 30)
    let mealPlan = MealPlan(items: [item1, item2])

    ctx.insert(chicken)
    ctx.insert(rice)
    ctx.insert(item1)
    ctx.insert(item2)
    ctx.insert(mealPlan)

    return NavigationStack {
        TimerRunView(mealPlan: mealPlan)
    }
    .modelContainer(container)
}

