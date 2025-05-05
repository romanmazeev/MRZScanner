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

        expectNoDifference(
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
            mrzKey: "",
            format: .td2(isVisaDocument: false),
            documentType: .other("I"),
            documentSubtype: .national,
            issuingCountry: .other("thirdTest"),
            name: .init(surname: "thirdTest", givenNames: "thirdTest"),
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
