//
//  BoundingRectConverter.swift
//
//
//  Created by Roman Mazeev on 01/12/2023.
//
//

import CoreImage
import Dependencies
import DependenciesMacros

@DependencyClient
struct BoundingRectConverter: Sendable {
    var convert: @Sendable (_ results: [TextRecognizer.Result], _ validLines: [Validator.Result]) -> ScannedBoundingRects = { _, _ in .init(valid: [], invalid: []) }
}

extension BoundingRectConverter: DependencyKey {
    static var liveValue: Self {
        .init { results, validLines in
            let allBoundingRects = results.map(\.boundingRect)
            let validRectIndexes = Set(validLines.map(\.index))
            
            var validScannedBoundingRects: [CGRect] = []
            var invalidScannedBoundingRects: [CGRect] = []
            allBoundingRects.enumerated().forEach {
                if validRectIndexes.contains($0.offset) {
                    validScannedBoundingRects.append($0.element)
                } else {
                    invalidScannedBoundingRects.append($0.element)
                }
            }
            
            return .init(valid: validScannedBoundingRects, invalid: invalidScannedBoundingRects)
        }
    }
}

extension DependencyValues {
    var boundingRectConverter: BoundingRectConverter {
        get { self[BoundingRectConverter.self] }
        set { self[BoundingRectConverter.self] = newValue }
    }
}

#if DEBUG
extension BoundingRectConverter: TestDependencyKey {
    static let testValue = Self()
}
#endif
