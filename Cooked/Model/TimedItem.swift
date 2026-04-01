//
//  TimedItem.swift
//  Cooked
//
//  Created by David James on 02/02/2026.
//

import Foundation

/// Any item, e.g. `CookingItem` or `CookingTimer`
/// that has a cooking time in seconds.
protocol TimedItem {
    var timeInSeconds: Int { get }
}

extension TimedItem {
    
    /// The duration represented by this item's time in seconds.
    var duration: Duration {
        .seconds(timeInSeconds)
    }
    
    /// Remaining time
    ///
    /// e.g. 1:20:00
    var relativeTimeDisplay: String {
        let hours = timeInSeconds / 3600
        if hours > 0 {
            return duration.formatted(.time(pattern: .hourMinuteSecond))
        } else {
            return duration.formatted(.time(pattern: .minuteSecond))
        }
    }
    
    /// Clock time when done
    ///
    /// e.g. 2:00 PM current time + 1:20 remaining time = 3:20 PM done
    var absoluteTimeDisplay: String {
        let doneDate = Date.now.addingTimeInterval(TimeInterval(timeInSeconds))
        return doneDate.formatted(date: .omitted, time: .shortened)
    }
    
    var unitDisplay: String {
        duration.formatted(.units(
            allowed: [.hours, .minutes],
            width: .wide,
            maximumUnitCount: 1
        ))
    }
}


