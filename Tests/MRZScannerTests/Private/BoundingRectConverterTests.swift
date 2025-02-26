//
//  BoundingRectConverterTests.swift
//
//
//  Created by Roman Mazeev on 01/12/2023.
//

@testable import MRZScanner
import XCTest

final class BoundingRectConverterTests: XCTestCase {
    func testConverterEmpty() {
        let result = BoundingRectConverter.liveValue.convert([], [])
        XCTAssert(result.valid.isEmpty)
        XCTAssert(result.invalid.isEmpty)
    }

    func testConverter() {
        let firstResult = TextRecognizer.Result(results: ["test"], boundingRect: .init(x: 0, y: 0, width: 20, height: 20))
        let secondResult = TextRecognizer.Result(results: ["test"], boundingRect: .zero)
        let thirdResult = TextRecognizer.Result(results: ["test"], boundingRect: .init(x: 1, y: 1, width: 40, height: 60))

        let result = BoundingRectConverter.liveValue.convert(
            [
                firstResult,
                secondResult,
                thirdResult
            ],
            [
                Validator.Result(result: "test", index: 0),
                Validator.Result(result: "test", index: 1),
                Validator.Result(result: "test", index: 1)
            ]
        )
        XCTAssertEqual(result.valid, [firstResult.boundingRect, secondResult.boundingRect])
        XCTAssertEqual(result.invalid, [thirdResult.boundingRect])
    }
}
