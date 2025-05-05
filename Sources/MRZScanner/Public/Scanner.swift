//
//  Scanner.swift
//
//
//  Created by Roman Mazeev on 12.07.2021.
//

import CoreImage
import Dependencies
import Vision

// MARK: - Image stream scanning

@available(macOS 15.0, iOS 18.0, *)
public extension AsyncSequence<CIImage, Never> {
    func scanForMRZCode(configuration: ScanningConfiguration) -> any AsyncSequence<ScanningResult<TrackerResult>, Error> {
        @Dependency(\.tracker.create) var createTracker
        let tracker = createTracker()

        return map { image in
            let (parsedResult, boundingRects) = try await scanMRZCode(from: image, configuration: configuration)
            guard let parsedResult else {
                return ScanningResult<TrackerResult>(results: tracker.seenResults, boundingRects: boundingRects)
            }

            tracker.track(result: parsedResult)
            return .init(results: tracker.seenResults, boundingRects: boundingRects)
        }
    }
}

// TODO: Remove once macOS 15.0 & iOS 18.0 become the minimum deployment target.
public extension AsyncStream<CIImage> {
    func scanForMRZCode(configuration: ScanningConfiguration) -> AsyncThrowingMapSequence<AsyncStream<CIImage>, ScanningResult<TrackerResult>> {
        @Dependency(\.tracker.create) var createTracker
        let tracker = createTracker()

        return map { image in
            let (parsedResult, boundingRects) = try await scanMRZCode(from: image, configuration: configuration)
            guard let parsedResult else {
                return ScanningResult<TrackerResult>(results: tracker.seenResults, boundingRects: boundingRects)
            }

            tracker.track(result: parsedResult)
            return .init(results: tracker.seenResults, boundingRects: boundingRects)
        }
    }
}

// MARK: - Single image scanning

public extension CIImage {
    func scanForMRZCode(configuration: ScanningConfiguration) async throws -> ScanningResult<ParserResult>? {
        let (parsedResult, boundingRects) = try await scanMRZCode(from: self, configuration: configuration)
        guard let parsedResult else { return nil }

        return .init(results: parsedResult, boundingRects: boundingRects)
    }
}

// MARK: - Generic

/// Configuration for scanning.
public struct ScanningConfiguration: Sendable {
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

private func scanMRZCode(from image: CIImage, configuration: ScanningConfiguration) async throws -> (ParserResult?, ScannedBoundingRects) {
    @Dependency(\.textRecognizer) var textRecognizer
    let recognizerResult = try await textRecognizer.recognize(configuration: configuration, scanningImage: image)

    @Dependency(\.validator) var validator
    let validatedResults = validator.getValidatedResults(possibleLines: recognizerResult.map(\.results))

    @Dependency(\.boundingRectConverter) var boundingRectConverter
    let boundingRects = boundingRectConverter.convert(results: recognizerResult, validLines: validatedResults)

    @Dependency(\.parser) var parser
    return (parser.parse(mrzLines: validatedResults.map(\.result)), boundingRects)
}
