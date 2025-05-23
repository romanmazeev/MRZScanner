//
//  SharedMocks.swift
//  
//
//  Created by Roman Mazeev on 01/12/2023.
//

import Foundation
@testable import MRZScanner

extension ParserResult {
    static var mock: Self {
        .init(
            mrzKey: "",
            format: .td3(isVisaDocument: false),
            documentType: .passport,
            documentSubtype: nil,
            issuingCountry: .other("test"),
            name: .init(surname: "test", givenNames: "test"),
            documentNumber: "test",
            nationalityCountryCode: "test",
            birthdate: .mock,
            sex: .male,
            expiryDate: .mock,
            optionalData: "",
            optionalData2: ""
        )
    }

    static var secondMock: Self {
        .init(
            mrzKey: "",
            format: .td1,
            documentType: .passport,
            documentSubtype: .other("D"),
            issuingCountry: .other("secondTest"),
            name: .init(surname: "secondTest", givenNames: "secondTest"),
            documentNumber: "secondTest",
            nationalityCountryCode: "secondTest",
            birthdate: .mock,
            sex: .male,
            expiryDate: .mock,
            optionalData: "",
            optionalData2: ""
        )
    }
}

extension ScannedBoundingRects {
    static var mock: Self { .init(valid: [.init(), .init()], invalid: [.init()]) }
}

extension Date {
    static var mock: Self {
        .init(timeIntervalSince1970: 0)
    }
}

extension ScanningConfiguration {
    static func mock(roi: CGRect = .init(x: 0, y: 0, width: 1, height: 1)) -> Self {
        .init(
            orientation: .up,
            regionOfInterest: roi,
            minimumTextHeight: 0,
            recognitionLevel: .fast
        )
    }
}
