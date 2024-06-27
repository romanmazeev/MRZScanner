//
//  ScannedBoundingRectsHelper.swift
//
//
//  Created by Roman Mazeev on 26/06/2024.
//

import Vision

public extension ScannedBoundingRects {
    /// Converts the normalized bounding rects to image rects
    /// - Parameters: imageWidth: Width of the image
    /// - Parameters: imageHeight: Height of the image
    func convertedToImageRects(imageWidth: Int, imageHeight: Int) -> Self {
        .init(
            valid: valid.map { VNImageRectForNormalizedRect($0, imageWidth, imageHeight) },
            invalid: invalid.map { VNImageRectForNormalizedRect($0, imageWidth, imageHeight) }
        )
    }
}
