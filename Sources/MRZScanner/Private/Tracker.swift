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
    var create: @Sendable () -> TrackerProtocol = { TrackerImplementation() }
}

extension Tracker: DependencyKey {
    static var liveValue: Self {
        .init(
            create: { TrackerImplementation() }
        )
    }
}

protocol TrackerProtocol: Sendable {
    var seenResults: TrackerResult { get }

    func track(result: ParserResult)
}

private final class TrackerImplementation: TrackerProtocol {
    private let results: LockIsolated<TrackerResult> = .init([:])

    var seenResults: TrackerResult {
        results.value
    }

    func track(result: ParserResult) {
        results.withValue { $0[result, default: 0] += 1 }
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
