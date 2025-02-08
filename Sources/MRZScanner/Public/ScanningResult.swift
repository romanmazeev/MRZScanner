//
//  ScanningResult.swift
//  
//
//  Created by Roman Mazeev on 29/12/2022.
//

import CoreImage
import MRZParser

/// Bounding rectangles of the scanned text.
/// - Note: Rects are normalized and use a bottom-right coordinate system.
public struct ScannedBoundingRects: Sendable {
    public let valid: [CGRect], invalid: [CGRect]

    public init(valid: [CGRect], invalid: [CGRect]) {
        self.valid = valid
        self.invalid = invalid
    }
}

/// Represents the result of the scanning process.
/// - Note: In case of MRZ scanning, the result is sent as each frame is scanned.
public struct ScanningResult<T: Sendable>: Sendable {
    /// Results of scanning.
    public let results: T
    public let boundingRects: ScannedBoundingRects
}

public extension ScanningResult where T == TrackerResult {
    /// Returns the best result that has been seen at least `repetitions` times.
    /// - Parameter repetitions: Minimum number of repetitions that the result should be found.
    /// - Returns: The best result.
    func best(repetitions: Int) -> ParserResult? {
        guard let maxElement = results.max(by: { $0.value < $1.value }) else {
            return nil
        }

        return maxElement.value >= repetitions ? maxElement.key : nil
    }
}
