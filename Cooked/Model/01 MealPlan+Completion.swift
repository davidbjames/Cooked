//
//  MealPlan+CompletionEvent.swift
//  Cooked
//
//  Created by David James on 18/03/2026.
//

extension MealPlan {
    
    struct CompletionEvent: Hashable, TimedItem {
        
        // Seconds from timer start when this is complete
        let timeInSeconds: Int
        // Items that should start for this completion
        let startingItems: [CookingItem]
        // Whether this is the final completion
        let isFinal: Bool
        
        var title: String {
            if isFinal {
                "Everything done"
            } else {
                "Start \(startingItems.map { $0.foodName }.joined(separator: ", "))"
            }
        }
        
        init(atSeconds: Int, startingItems: [CookingItem] = [], isCompletion: Bool = false) {
            self.timeInSeconds = atSeconds
            self.startingItems = startingItems
            self.isFinal = isCompletion
        }
    }
    
    // Schedule of ring events:
    // - For each item, fire completion at (overall - item.duration) to start it (if > 0)
    // - Ring at overall for completion
    // - If any items start at 0, you may choose to include a ring at 0; we omit it by default
    var createCompletionSchedule: [CompletionEvent] {
        
        guard let items else {
            return []
        }
        
        let totalSeconds = timeInSeconds
        
        guard totalSeconds > 0 else {
            return []
        }
        
        // Map start offsets to items
        var starts: [Int: [CookingItem]] = [:]
        for item in items {
            // when this item should start so that it will be
            // done at the same time as the longest item
            let offset = totalSeconds - item.timeInSeconds
            //            if offset > 0 {
            starts[offset, default: []].append(item)
            //            }
        }
        
        var events: [CompletionEvent] = starts
            .map { (offset, items) in
                CompletionEvent(atSeconds: offset, startingItems: items)
            }
            .sorted { $0.timeInSeconds < $1.timeInSeconds }
        
        // Append completion ring
        events.append(CompletionEvent(atSeconds: totalSeconds, isCompletion: true))
        return events
    }

}
