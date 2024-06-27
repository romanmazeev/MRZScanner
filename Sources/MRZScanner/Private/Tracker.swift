//
//  Tracker.swift
//
//
//  Created by Roman Mazeev on 01/12/2023.
//

import Dependencies
import DependenciesMacros

public typealias TrackerResult = [ParserResult: Int]

@DependencyClient
struct Tracker: Sendable {
    var currentResults: @Sendable () -> TrackerResult = { [:] }
    var track: @Sendable (_ result: ParserResult) -> Void
}

extension Tracker: DependencyKey {
    static var liveValue: Self {
        let seenResults: LockIsolated<TrackerResult> = .init([:])

        return .init(
            currentResults: { seenResults.value },
            track: { result in
                seenResults.withValue { seenResults in
                    seenResults[result, default: 0] += 1
                }
            }
        )
    }
}

extension DependencyValues {
    var tracker: Tracker {
        get { self[Tracker.self] }
        set { self[Tracker.self] = newValue }
    }
}

#if DEBUG
extension Tracker: TestDependencyKey {
    static let testValue = Self()
}
#endif
