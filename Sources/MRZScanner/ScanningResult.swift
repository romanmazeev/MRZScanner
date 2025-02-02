//
//  ScanningResult.swift
//  
//
//  Created by Roman Mazeev on 29/12/2022.
//

import CoreGraphics

public struct ScanedBoundingRects {
    public let valid: [CGRect], invalid: [CGRect]

    public func convertedToImageRects(imageWidth: Int, imageHeight: Int) -> Self {
        .init(
            valid: valid.map { MRZScanner.convertRect(to: .imageRect, rect: $0, imageWidth: imageWidth, imageHeight: imageHeight) },
            invalid: invalid.map { MRZScanner.convertRect(to: .imageRect, rect: $0, imageWidth: imageWidth, imageHeight: imageHeight) }
        )
    }

    public init(valid: [CGRect], invalid: [CGRect]) {
        self.valid = valid
        self.invalid = invalid
    }
}

public struct ScanningResult<T> {
    public let result: T
    public let boundingRects: ScanedBoundingRects
}

public enum LiveScanningResult<T> {
    case notFound(ScanedBoundingRects)
    case found(ScanningResult<T>)
}
