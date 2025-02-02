//
//  ViewModel.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

@preconcurrency import AVFoundation
@preconcurrency import SwiftUI
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

    func startCamera() async {
        do {
            try await camera.startCamera()
        } catch {
            result = .failure(error)
        }
    }

    func startMRZScanning(cameraRect: CGRect, mrzRect: CGRect) async {
        guard let imageStream = await camera.imageStream else { return }

        do {
            try await scanImageStream(imageStream, cameraRect: cameraRect, mrzRect: mrzRect)
        } catch {
            result = .failure(error)
        }
    }

    private func scanImageStream(_ imageStream: AsyncStream<CIImage>, cameraRect: CGRect, mrzRect: CGRect) async throws {
        for try await scanningResult in imageStream.scanForMRZCode(
            configuration: .init(
                orientation: .up,
                regionOfInterest: VNNormalizedRectForImageRect(
                    correctCoordinates(to: .leftTop, rect: mrzRect),
                    Int(cameraRect.width),
                    Int(cameraRect.height)
                ),
                minimumTextHeight: 0.1,
                recognitionLevel: .fast
            )
        ) {
            boundingRects = correctBoundingRects(to: .center, rects: scanningResult.boundingRects, mrzRect: mrzRect)
            if let bestResult = scanningResult.best(repetitions: 5) {
                result = .success(bestResult)
                boundingRects = nil
                return
            }
        }
    }

    // MARK: - Correct CGRect origin from top left to center

    enum CorrectionType {
        case center
        case leftTop
    }

    private func correctBoundingRects(to type: CorrectionType, rects: ScannedBoundingRects, mrzRect: CGRect) -> ScannedBoundingRects {
        let convertedCoordinates = rects.convertedToImageRects(imageWidth: Int(mrzRect.width), imageHeight: Int(mrzRect.height))
        let correctedMRZRect = correctCoordinates(to: .leftTop, rect: mrzRect)

        func correctRects(_ rects: [CGRect]) -> [CGRect] {
            rects
                .map { correctCoordinates(to: type, rect: $0) }
                .map { .init(origin: .init(x: $0.origin.x + correctedMRZRect.minX, y: $0.origin.y + correctedMRZRect.minY), size: $0.size) }
        }

        return .init(valid: correctRects(convertedCoordinates.valid),  invalid: correctRects(convertedCoordinates.invalid))
    }

    private func correctCoordinates(to type: CorrectionType, rect: CGRect) -> CGRect {
        let x = type == .center ? rect.minX + rect.width / 2 : rect.minX - rect.width / 2
        let y = type == .center ? rect.minY + rect.height / 2 : rect.minY - rect.height / 2
        return CGRect(origin: .init(x: x, y: y), size: rect.size)
    }
}
