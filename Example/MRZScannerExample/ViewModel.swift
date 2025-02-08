//
//  ViewModel.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

import AVFoundation
import CoreImage
import MRZScanner
import Vision

@MainActor
final class ViewModel: ObservableObject {
    private let camera = Camera()
    var captureSession: AVCaptureSession {
        camera.captureSession
    }

    @Published var boundingRects: ScannedBoundingRects?
    @Published var result: Result<ParserResult, Error>?

    private var cameraRect: CGRect?

    func startCamera() async {
        do {
            try await camera.startCamera()
        } catch {
            result = .failure(error)
        }
    }

    func setContentRects(cameraRect: CGRect, mrzRect: CGRect) {
        self.cameraRect = cameraRect
    }

    func startMRZScanning(mrzRect: CGRect) async {
        do {
            try await scanImageStream(camera.imageStream, mrzRect: mrzRect)
        } catch {
            result = .failure(error)
        }
    }

    private func scanImageStream(_ imageStream: AsyncStream<CIImage>, mrzRect: CGRect) async throws {
        guard let cameraRect else {
            throw ScanningError.cameraRectNotSet
        }

        // Convert from view coordinates to normalized coordinates.
        let normalisedMRZRect = VNNormalizedRectForImageRect(
            convertRect(mrzRect, to: .bottom, containerHeight: cameraRect.height),
            Int(cameraRect.width),
            Int(cameraRect.height)
        )

        for try await scanningResult in imageStream.scanForMRZCode(
            configuration: .init(
                orientation: .up,
                regionOfInterest: normalisedMRZRect,
                minimumTextHeight: 0.1,
                recognitionLevel: .fast
            )
        ) {
            boundingRects = correctBoundingRects(
                rects: scanningResult.boundingRects,
                normalisedMRZRect: normalisedMRZRect,
                cameraRect: cameraRect
            )

            if let bestResult = scanningResult.best(repetitions: 5) {
                result = .success(bestResult)
                boundingRects = nil
                return
            }
        }
    }

    enum CoordinateSystem {
        case bottom
        case top
    }

    private func correctBoundingRects(
        rects: ScannedBoundingRects,
        normalisedMRZRect: CGRect,
        cameraRect: CGRect
    ) -> ScannedBoundingRects {
        func translateToRootView(normalizedRect: CGRect) -> CGRect {
            // Convert from normalized coordinates inside the MRZ to view coordinates inside the cameraRect.
            let imageRect = VNImageRectForNormalizedRectUsingRegionOfInterest(
                normalizedRect,
                Int(cameraRect.width),
                Int(cameraRect.height),
                normalisedMRZRect
            )

            return convertRect(imageRect, to: .top, containerHeight: cameraRect.height)
        }

        return ScannedBoundingRects(
            valid: rects.valid.map { translateToRootView(normalizedRect: $0) },
            invalid: rects.invalid.map { translateToRootView(normalizedRect: $0) }
        )
    }

    /// Converts a rectangle's Y-coordinate between top-based and bottom-based coordinate systems.
    private func convertRect(_ rect: CGRect, to coordinateSystem: CoordinateSystem, containerHeight: CGFloat) -> CGRect {
        .init(
            x: rect.origin.x,
            y: coordinateSystem == .top ? containerHeight - rect.origin.y - rect.height : containerHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}

enum ScanningError: Error {
    case cameraRectNotSet
}
