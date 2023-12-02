//
//  Scanner.swift
//
//
//  Created by Roman Mazeev on 12.07.2021.
//

import CoreImage
import Dependencies
import Vision

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

// MARK: Image stream scanning

public extension AsyncStream<CIImage> {
    func scanForMRZCode(
        configuration: ScanningConfiguration,
        scanningPriority: TaskPriority? = nil
    ) -> AsyncThrowingStream<ScanningResult<TrackerResult>, Error> {
        .init { continuation in
            let scanningTask = Task {
                let seenResults: LockIsolated<TrackerResult> = .init([:])

                for await image in self {
                    await withTaskGroup(of: Void.self) { group in
                        _ = group.addTaskUnlessCancelled(priority: scanningPriority) {
                            do {
                                @Dependency(\.textRecognizer) var textRecognizer
                                let recognizerResult = try await textRecognizer.recognize(configuration, image)

                                @Dependency(\.validator) var validator
                                let validatedResults = validator.getValidatedResults(recognizerResult.map(\.results))

                                @Dependency(\.boundingRectConverter) var boundingRectConverter
                                let boundingRects = boundingRectConverter.convert(recognizerResult, validatedResults)

                                @Dependency(\.parser) var parser
                                guard let parsedResult = parser.parse(validatedResults.map(\.result)) else {
                                    continuation.yield(.init(results: seenResults.value, boundingRects: boundingRects))
                                    return
                                }

                                @Dependency(\.tracker) var tracker
                                seenResults.withValue {
                                    $0 = tracker.updateResults(seenResults.value, parsedResult)
                                }

                                continuation.yield(.init(results: seenResults.value, boundingRects: boundingRects))
                            } catch {
                                continuation.finish(throwing: error)
                            }
                        }
                    }
                }
            }

            continuation.onTermination = { _ in
                scanningTask.cancel()
            }
        }
    }
}

// MARK: Single image scanning

public extension CIImage {
    enum ScanningError: Error {
        case codeNotFound
    }

    func scanForMRZCode(configuration: ScanningConfiguration) async throws -> ScanningResult<ParserResult> {
        @Dependency(\.textRecognizer) var textRecognizer
        let recognizerResult = try await textRecognizer.recognize(configuration, self)

        @Dependency(\.validator) var validator
        let validatedResults = validator.getValidatedResults(recognizerResult.map(\.results))

        @Dependency(\.boundingRectConverter) var boundingRectConverter
        let boundingRects = boundingRectConverter.convert(recognizerResult, validatedResults)

        @Dependency(\.parser) var parser
        guard let parsedResult = parser.parse(validatedResults.map(\.result)) else {
            throw ScanningError.codeNotFound
        }

        return .init(results: parsedResult, boundingRects: boundingRects)
    }
}
