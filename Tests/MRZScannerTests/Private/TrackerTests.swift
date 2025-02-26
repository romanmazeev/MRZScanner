//
//  TrackerTests.swift
//
//
//  Created by Roman Mazeev on 01/12/2023.
//

@testable import MRZScanner
import XCTest

final class TrackerTests: XCTestCase {
    func testTrackAndCurrentResults() throws {
        let tracker = Tracker.liveValue.create()

        let firstResults = tracker.seenResults
        XCTAssertTrue(firstResults.isEmpty)

        tracker.track(result: .mock)
        let secondResults = tracker.seenResults
        let secondResult = try XCTUnwrap(secondResults.first)
        XCTAssertEqual(secondResult.key, .mock)
        XCTAssertEqual(secondResult.value, 1)

        tracker.track(result: .secondMock)
        let thirdResults = tracker.seenResults
        XCTAssertEqual(thirdResults.count, 2)
        XCTAssertEqual(thirdResults[.secondMock], 1)

        tracker.track(result: .mock)
        let forthResults = tracker.seenResults
        XCTAssertEqual(forthResults.count, 2)
        XCTAssertEqual(forthResults[.mock], 2)
    }
}
