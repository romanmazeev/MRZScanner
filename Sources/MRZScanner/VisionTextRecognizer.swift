//
//  TextRecognizer.swift
//  
//
//  Created by Roman Mazeev on 13.07.2021.
//

import Vision
import CoreImage

struct VisionTextRecognizer {
    struct Result {
        let results: [String]
        let boundingRect: CGRect
    }

    static func recognize(scanningImage: CIImage, configuration: ScanningConfiguration) async throws -> [Result] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { response, _ in
                guard let visionResults = response.results as? [VNRecognizedTextObservation] else { return }
                continuation.resume(returning: visionResults.map {
                    Result(results: $0.topCandidates(10).map(\.string), boundingRect: $0.boundingBox)
                })
            }

            request.regionOfInterest = configuration.regionOfInterest
            request.minimumTextHeight = configuration.minimumTextHeight
            request.recognitionLevel = configuration.recognitionLevel
            request.usesLanguageCorrection = false

            do {
                try VNImageRequestHandler(ciImage: scanningImage, orientation: configuration.orientation).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private init() {}
}
