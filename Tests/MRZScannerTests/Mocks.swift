//
//  Mocks.swift
//  
//
//  Created by Roman Mazeev on 01/12/2023.
//

import Foundation
@testable import MRZScanner
import Vision

extension ParserResult {
    static var mock: Self {
        .init(
            format: .td3,
            documentType: .passport,
            documentTypeAdditional: "A",
            countryCode: "test",
            surnames: "test",
            givenNames: "test",
            documentNumber: "test",
            nationalityCountryCode: "test",
            birthdate: .mock,
            sex: .male,
            expiryDate: .mock,
            optionalData: "",
            optionalData2: ""
        )
    }
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

extension ScannedBoundingRects: Equatable {
    public static func == (lhs: ScannedBoundingRects, rhs: ScannedBoundingRects) -> Bool {
        lhs.valid == rhs.valid &&
        lhs.invalid == rhs.invalid
    }
}

extension TextRecognizer.Result: Equatable {
    public static func == (lhs: TextRecognizer.Result, rhs: TextRecognizer.Result) -> Bool {
        lhs.results == rhs.results &&
        lhs.boundingRect == rhs.boundingRect
    }
}

extension ScanningConfiguration: Equatable {
    public static func == (lhs: ScanningConfiguration, rhs: ScanningConfiguration) -> Bool {
        lhs.orientation == rhs.orientation &&
        lhs.regionOfInterest == rhs.regionOfInterest &&
        lhs.minimumTextHeight == rhs.minimumTextHeight &&
        lhs.recognitionLevel == rhs.recognitionLevel
    }
}
