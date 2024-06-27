//
//  ScanningResultTests.swift
//
//
//  Created by Roman Mazeev on 26/06/2024.
//

import CustomDump
@testable import MRZScanner
import XCTest

final class ScanningResultTests: XCTestCase {
    func testBestExist() throws {
        let result: ScanningResult<TrackerResult> = .init(
            results: [
                .mock: 1,
                .secondMock: 30,
                .thirdMock: 9
            ],
            boundingRects: .mock
        )

        XCTAssertNoDifference(
            result.best(repetitions: 9),
            .secondMock
        )
    }

    func testBestNotExist() throws {
        let result: ScanningResult<TrackerResult> = .init(
            results: [
                .mock: 1,
            ],
            boundingRects: .mock
        )

        XCTAssertNil(result.best(repetitions: 9))
    }

    func testNoResults() throws {
        let result: ScanningResult<TrackerResult> = .init(
            results: [:],
            boundingRects: .mock
        )

        XCTAssertNil(result.best(repetitions: 9))
    }
}

private extension ParserResult {
    static var thirdMock: Self {
        .init(
            format: .td2,
            documentType: .id,
            documentTypeAdditional: "r",
            countryCode: "thirdTest",
            surnames: "thirdTest",
            givenNames: "thirdTest",
            documentNumber: "thirdTest",
            nationalityCountryCode: "thirdTest",
            birthdate: .mock,
            sex: .male,
            expiryDate: .mock,
            optionalData: "",
            optionalData2: ""
        )
    }
}
