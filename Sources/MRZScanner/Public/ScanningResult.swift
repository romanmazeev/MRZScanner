//
//  ScanningResult.swift
//  
//
//  Created by Roman Mazeev on 29/12/2022.
//

import CoreGraphics
import Vision
import MRZParser

public typealias TrackerResult = [ParserResult: Int]
public typealias ParserResult = MRZResult

extension ParserResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(format)
        hasher.combine(documentType)
        hasher.combine(documentTypeAdditional)
        hasher.combine(countryCode)
        hasher.combine(surnames)
        hasher.combine(givenNames)
        hasher.combine(documentNumber)
        hasher.combine(nationalityCountryCode)
        hasher.combine(birthdate)
        hasher.combine(sex)
        hasher.combine(expiryDate)
        hasher.combine(optionalData)
        hasher.combine(optionalData2)
    }

    public static func == (lhs: MRZResult, rhs: MRZResult) -> Bool {
        lhs.format == rhs.format &&
        lhs.documentType == rhs.documentType &&
        lhs.documentTypeAdditional == rhs.documentTypeAdditional &&
        lhs.countryCode == rhs.countryCode &&
        lhs.surnames == rhs.surnames &&
        lhs.givenNames == rhs.givenNames &&
        lhs.documentNumber == rhs.documentNumber &&
        lhs.nationalityCountryCode == rhs.nationalityCountryCode &&
        lhs.birthdate == rhs.birthdate &&
        lhs.sex == rhs.sex &&
        lhs.expiryDate == rhs.expiryDate &&
        lhs.optionalData == rhs.optionalData &&
        lhs.optionalData2 == rhs.optionalData2
    }
}

public struct ScanningResult<T> {
    public let results: T
    public let boundingRects: ScannedBoundingRects
}

public extension ScanningResult where T == [ParserResult: Int] {
    func best(repetitions: Int) -> ParserResult? {
         results.max(by: { $0.value > $1.value })?.key
    }
}

public struct ScannedBoundingRects {
    public let valid: [CGRect], invalid: [CGRect]

    public func convertedToImageRects(imageWidth: Int, imageHeight: Int) -> Self {
        .init(
            valid: valid.map { VNImageRectForNormalizedRect($0, imageWidth, imageHeight) },
            invalid: invalid.map { VNImageRectForNormalizedRect($0, imageWidth, imageHeight) }
        )
    }

    public init(valid: [CGRect], invalid: [CGRect]) {
        self.valid = valid
        self.invalid = invalid
    }
}
