//
//  MRZScanner.swift
//  
//
//  Created by Roman Mazeev on 12.07.2021.
//

import CoreImage
import Vision
import MRZParser

public struct ScanningConfiguration {
    let orientation: CGImagePropertyOrientation
    let regionOfInterest: CGRect
    let minimumTextHeight: Float
    let recognitionLevel: VNRequestTextRecognitionLevel

    public init(orientation: CGImagePropertyOrientation, regionOfInterest: CGRect, minimumTextHeight: Float, recognitionLevel: VNRequestTextRecognitionLevel) {
        self.orientation = orientation
        self.regionOfInterest = regionOfInterest
        self.minimumTextHeight = minimumTextHeight
        self.recognitionLevel = recognitionLevel
    }
}

public struct MRZScanner {
    public static func scanLive(imageStream: AsyncStream<CIImage>, configuration: ScanningConfiguration) -> AsyncThrowingStream<LiveScanningResult<MRZResult>, Error> {
        let frequencyTracker = MRZFrequencyTracker(frequency: 2)

        return imageStream.map { image in
            let recognizerResults = try await VisionTextRecognizer.recognize(scanningImage: image, configuration: configuration)
            let validatedResults = MRZValidator.getValidatedResults(from: recognizerResults.map(\.results))

            let boundingRects = getScannedBoundingRects(from: recognizerResults, validLines: validatedResults)
            guard let parsedResult = MRZParser.init(isOCRCorrectionEnabled: true).parse(mrzLines: validatedResults.map(\.result)) else {
                return .notFound(boundingRects)
            }

            return frequencyTracker.isResultStable(parsedResult)
                ? LiveScanningResult.found(.init(result: parsedResult, boundingRects: boundingRects))
                : .notFound(boundingRects)
        }
    }

    public static func scanSingle(image: CIImage, configuration: ScanningConfiguration) async throws -> ScanningResult<MRZResult> {
        let recognizerResults = try await VisionTextRecognizer.recognize(scanningImage: image, configuration: configuration)
        let validatedResults = MRZValidator.getValidatedResults(from: recognizerResults.map(\.results))
        guard let parsedResult = MRZParser.init(isOCRCorrectionEnabled: true).parse(mrzLines: validatedResults.map(\.result)) else {
            throw MRZScannerError.codeNotFound
        }

        return .init(result: parsedResult, boundingRects: getScannedBoundingRects(from: recognizerResults, validLines: validatedResults))
    }

    private static func getScannedBoundingRects(
        from results: [VisionTextRecognizer.Result],
        validLines: [MRZValidator.Result]
    ) -> ScanedBoundingRects {
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

    private init() {}
}

public extension MRZScanner {
    enum RectConvertationType {
        case imageRect
        case normalizedRect
    }

    static func convertRect(to type: RectConvertationType, rect: CGRect, imageWidth: Int, imageHeight: Int) -> CGRect {
        switch type {
        case .imageRect:
            return VNImageRectForNormalizedRect(rect, imageWidth, imageHeight)
        case .normalizedRect:
            return VNNormalizedRectForImageRect(rect, imageWidth, imageHeight)
        }
    }
}

enum MRZScannerError: Error {
    case codeNotFound
}
