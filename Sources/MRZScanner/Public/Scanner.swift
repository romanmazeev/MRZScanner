//
//  Scanner.swift
//
//
//  Created by Roman Mazeev on 12.07.2021.
//

import CoreImage
import Dependencies
import Vision

/// Configuration for scanning
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

// MARK: Image stream scanning

public extension AsyncStream<CIImage> {
    func scanForMRZCode(configuration: ScanningConfiguration) -> AsyncThrowingStream<ScanningResult<TrackerResult>, Error> {
        @Dependency(\.tracker) var tracker

        return map { image in
            @Dependency(\.textRecognizer) var textRecognizer
            let recognizerResult = try await textRecognizer.recognize(configuration: configuration, scanningImage: image)

            @Dependency(\.validator) var validator
            let validatedResults = validator.getValidatedResults(possibleLines: recognizerResult.map(\.results))

            @Dependency(\.boundingRectConverter) var boundingRectConverter
            async let boundingRects = boundingRectConverter.convert(results: recognizerResult, validLines: validatedResults)

            @Dependency(\.parser) var parser
            guard let parsedResult = parser.parse(mrzLines: validatedResults.map(\.result)) else {
                return await .init(results: tracker.currentResults(), boundingRects: boundingRects)
            }

            tracker.track(result: parsedResult)
            return await .init(results: tracker.currentResults(), boundingRects: boundingRects)
        }.eraseToThrowingStream()
    }
}

// MARK: Single image scanning

public extension CIImage {
    enum ScanningError: Error {
        case codeNotFound
    }

    func scanForMRZCode(configuration: ScanningConfiguration) async throws -> ScanningResult<ParserResult> {
        @Dependency(\.textRecognizer) var textRecognizer
        let recognizerResult = try await textRecognizer.recognize(configuration: configuration, scanningImage: self)

        @Dependency(\.validator) var validator
        let validatedResults = validator.getValidatedResults(possibleLines: recognizerResult.map(\.results))

        @Dependency(\.boundingRectConverter) var boundingRectConverter
        async let boundingRects = boundingRectConverter.convert(results: recognizerResult, validLines: validatedResults)

        @Dependency(\.parser) var parser
        guard let parsedResult = parser.parse(mrzLines: validatedResults.map(\.result)) else {
            throw ScanningError.codeNotFound
        }

        return await .init(results: parsedResult, boundingRects: boundingRects)
    }
}
