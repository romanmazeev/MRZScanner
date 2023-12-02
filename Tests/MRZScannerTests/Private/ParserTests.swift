//
//  ParserTests.swift
//
//
//  Created by Roman Mazeev on 02/12/2023.
//

@testable import MRZScanner
import XCTest

/// More tests are located in `MRZParser` library
final class ParserTests: XCTestCase {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
        return formatter
    }()

    func testEmpty() {
        let parser = Parser.liveValue

        let result = parser.parse([])
        XCTAssertNil(result)
    }

    func testValid() throws {
        let parser = Parser.liveValue

        let mrzStrings = ["IRUTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<", "D231458907UTO7408122F1204159<<<<<<<6"]
        let result = ParserResult(
            format: .td2,
            documentType: .id,
            documentTypeAdditional: "R",
            countryCode: "UTO",
            surnames: "ERIKSSON",
            givenNames: "ANNA MARIA",
            documentNumber: "D23145890",
            nationalityCountryCode: "UTO",
            birthdate: try XCTUnwrap(dateFormatter.date(from: "740812")),
            sex: .female,
            expiryDate: try XCTUnwrap(dateFormatter.date(from: "120415")),
            optionalData: "",
            optionalData2: nil
        )

        XCTAssertEqual(parser.parse(mrzStrings), result)
    }

    func testInvalid() {
        let parser = Parser.liveValue

        let result = parser.parse(["P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<"])
        XCTAssertNil(result)
    }
}
