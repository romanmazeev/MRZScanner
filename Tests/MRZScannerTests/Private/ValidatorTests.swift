//
//  ValidatorTests.swift
//  
//
//  Created by Roman Mazeev on 01/12/2023.
//

@testable import MRZScanner
import XCTest

final class ValidatorTests: XCTestCase {
    func testEmpty() {
        XCTAssertTrue(Validator.liveValue.getValidatedResults([]).isEmpty)
    }

    func testWhitespaces() {
        let results = [
            [
                "",
                "P<UTOERIKSSON<<ANNA<MARIA<<<< <<<<<<<<<<<<<<",
                "te st",
            ],
            [
                "P<UTOERIKSSON<<ANNA<MARIA<<<<<< <<<<<<<<<<<<",
                " ",
                "test  "
            ]
        ]

        XCTAssertEqual(Validator.liveValue.getValidatedResults(results), [])
    }

    func testFoundLastWhenSearchingCurrentFormat() {
        let results = [
            [
                "",
                "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
                "test",
            ],
            [
                "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
                "",
                "test"
            ],
            // Stops here
            [
                "",
                "test",
                "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<"
            ],
        ]

        XCTAssertEqual(Validator.liveValue.getValidatedResults(results), [
            .init(result: "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<", index: 0),
            .init(result: "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<", index: 1)
        ])
    }

    func testFoundLastWhenSwitchingToAnotherFormat() {
        let results = [
            [
                "",
                "IRUTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<"
            ],
            [
                "IRUTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<",
                "test",
            ],
            // Stops here
        ]

        XCTAssertEqual(Validator.liveValue.getValidatedResults(results), [
            .init(result: "IRUTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<", index: 0),
            .init(result: "IRUTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<", index: 1)
        ])
    }
}

extension Validator.Result: @retroactive Equatable {
    public static func == (lhs: Validator.Result, rhs: Validator.Result) -> Bool {
        lhs.result == rhs.result && lhs.index == rhs.index
    }
}
