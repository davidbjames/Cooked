//
//  TimerRunView.swift
//  Cooked
//
//  Created by David James on 29/01/2026.
//

import SwiftUI
import SwiftData

struct TimerRunView: View {
    var timer: CookingTimer

    var body: some View {
        List {
            Section {
                HStack {
                    Text(timer.name)
                        .font(.title2.bold())
                    Spacer()
                }
                HStack {
                    Text("Total")
                    Spacer()
                    Text(timeString(seconds: timer.timeInSeconds))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Rings")) {
                ForEach(timer.createCompletionSchedule, id: \.self) { event in
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
        for: FoodItem.self, FoodVariable.self, CookingItem.self, CookingTimer.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext

    let chicken = FoodItem(name: "Chicken")
    let rice = FoodItem(name: "Rice")
    let item1 = CookingItem(foodItem: chicken, cookingTimeSeconds: 45 * 60)
    let item2 = CookingItem(foodItem: rice, cookingTimeSeconds: 30 * 60)
    let ct = CookingTimer(items: [item1, item2])

    ctx.insert(chicken)
    ctx.insert(rice)
    ctx.insert(item1)
    ctx.insert(item2)
    ctx.insert(ct)

    return NavigationStack {
        TimerRunView(timer: ct)
    }
    .modelContainer(container)
}

