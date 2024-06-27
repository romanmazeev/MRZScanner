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

        XCTAssertEqual(
            result.convertedToImageRects(imageWidth: 10, imageHeight: 10),
            .init(
                valid: [
                    .init(x: 0, y: 0, width: 200, height: 200),
                    .zero
                ],
                invalid: [
                    .init(x: 10, y: 10, width: 400, height: 600)
                ]
            )
        )
    }
}

extension ScannedBoundingRects: @retroactive Equatable {
    public static func == (lhs: ScannedBoundingRects, rhs: ScannedBoundingRects) -> Bool {
        lhs.valid == rhs.valid &&
        lhs.invalid == rhs.invalid
    }
}
