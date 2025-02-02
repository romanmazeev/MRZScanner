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
        let tracker = Tracker.liveValue

        let firstResults = tracker.currentResults()
        XCTAssertTrue(firstResults.isEmpty)

        tracker.track(result: .mock)
        let secondResults = tracker.currentResults()
        let secondResult = try XCTUnwrap(secondResults.first)
        XCTAssertEqual(secondResult.key, .mock)
        XCTAssertEqual(secondResult.value, 1)

        tracker.track(result: .secondMock)
        let thirdResults = tracker.currentResults()
        XCTAssertEqual(thirdResults.count, 2)
        XCTAssertEqual(thirdResults[.secondMock], 1)

        tracker.track(result: .mock)
        let forthResults = tracker.currentResults()
        XCTAssertEqual(forthResults.count, 2)
        XCTAssertEqual(forthResults[.mock], 2)
    }
}
