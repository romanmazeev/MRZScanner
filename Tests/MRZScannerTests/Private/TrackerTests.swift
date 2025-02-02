//
//  TrackerTests.swift
//
//
//  Created by Roman Mazeev on 01/12/2023.
//

@testable import MRZScanner
import XCTest

final class TrackerTests: XCTestCase {
    func testExisting() {
        let result = Tracker.liveValue.updateResults([.mock: 1], .mock)

        XCTAssertEqual(try XCTUnwrap(result.first?.key), .mock)
        XCTAssertEqual(try XCTUnwrap(result.first?.value), 2)
    }

    func testNew() {
        let result = Tracker.liveValue.updateResults([:], .mock)

        XCTAssertEqual(try XCTUnwrap(result.first?.key), .mock)
        XCTAssertEqual(try XCTUnwrap(result.first?.value), 1)
    }
}
