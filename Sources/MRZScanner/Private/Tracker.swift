//
//  Tracker.swift
//
//
//  Created by Roman Mazeev on 01/12/2023.
//

import Dependencies

struct Tracker: Sendable {
    let updateResults: @Sendable (_ results: TrackerResult, _ result: ParserResult) -> TrackerResult
}

extension Tracker: DependencyKey {
    static var liveValue: Self {
        .init(
            updateResults: { results, result in
                var seenResults = results
                guard let seenResultFrequency = seenResults[result] else {
                    seenResults[result] = 1
                    return seenResults
                }

                seenResults[result] = seenResultFrequency + 1
                return seenResults
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
    static var testValue: Self {
        Self(
            updateResults: unimplemented("Tracker.updateResults")
        )
    }
}
#endif
