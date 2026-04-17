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
