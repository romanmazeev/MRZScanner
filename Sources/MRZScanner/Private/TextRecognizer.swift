//
//  TextRecognizer.swift
//  
//
//  Created by Roman Mazeev on 13.07.2021.
//

import CoreImage
import Dependencies
import Vision

struct TextRecognizer: Sendable {
    struct Result {
        let results: [String]
        let boundingRect: CGRect
    }

    let recognize: @Sendable (_ configuration: ScanningConfiguration, _ scanningImage: CIImage) async throws -> [Result]
}

extension TextRecognizer: DependencyKey {
    static var liveValue: Self {
        .init(
            recognize: { request, scanningImage in
                try await withCheckedThrowingContinuation { continuation in
                    let visionRequest = VNRecognizeTextRequest { request, _ in
                        guard let visionResults = request.results as? [VNRecognizedTextObservation] else {
                            return
                        }

                        continuation.resume(returning: visionResults.map {
                            Result(results: $0.topCandidates(10).map(\.string), boundingRect: $0.boundingBox)
                        })
                    }
                    visionRequest.regionOfInterest = request.regionOfInterest
                    visionRequest.minimumTextHeight = request.minimumTextHeight
                    visionRequest.recognitionLevel = request.recognitionLevel
                    visionRequest.usesLanguageCorrection = false

                    do {
                        try VNImageRequestHandler(ciImage: scanningImage, orientation: request.orientation)
                            .perform([visionRequest])
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        )
    }
}

extension DependencyValues {
    var textRecognizer: TextRecognizer {
        get { self[TextRecognizer.self] }
        set { self[TextRecognizer.self] = newValue }
    }
}

#if DEBUG
extension TextRecognizer: TestDependencyKey {
    static var testValue: Self {
        Self(
            recognize: unimplemented("TextRecognizer.recognize")
        )
    }
}
#endif
