//
//  CollectionHelpers.swift
//  Cooked
//
//  Created by David James on 15/05/2026.
//

import Foundation

/// The position of an element within a collection.
enum CollectionPosition: Equatable {
    case start
    case intermediate(Int)
    case end
    
    var isStart: Bool {
        self == .start
    }
    var isEnd: Bool {
        self == .end
    }
    var isIntermediate: Bool {
        switch self {
        case .intermediate: true
        default: false
        }
    }
}

extension BidirectionalCollection {
    
    /// Returns a sequence of `(position: CollectionPosition, element: Element)` pairs,
    /// similar to `enumerated()` but allows you to check `position.isStart` or `position.isEnd`.
    func positionEnumerated() -> some Sequence<(position: CollectionPosition, element: Element)> {
        guard !isEmpty else {
            return AnySequence([])
        }
        let lastIndex = index(before: endIndex)
        return AnySequence(
            zip(indices, self).map { [startIndex] index, element in
                let position: CollectionPosition
                if index == startIndex {
                    position = .start
                } else if index == lastIndex {
                    position = .end
                } else {
                    position = .intermediate(self.distance(from: startIndex, to: index))
                }
                return (position, element)
            }
        )
    }
}
