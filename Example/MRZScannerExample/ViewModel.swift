//
//  ViewModel.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

import AVFoundation
import SwiftUI
import MRZScanner
import MRZParser
import Vision

final class ViewModel: ObservableObject {

    // MARK: Camera
    private let camera = Camera()
    @Published var cameraRect: CGRect?
    var captureSession: AVCaptureSession {
        camera.captureSession
    }

    func startCamera() {
        Task {
            await camera.start()
        }
    }

    // MARK: Scanning
    @Published var boundingRects: ScanedBoundingRects?
    @Published var mrzRect: CGRect?
    @Published var mrzResult: MRZResult?

    private var scanningTask: Task<(), Error>?

    func startMRZScanning() async throws {
        guard let cameraRect, let mrzRect else { return }

        let correctedMRZRect = correctCoordinates(to: .leftTop, rect: mrzRect)
        let roi = MRZScanner.convertRect(to: .normalizedRect, rect: correctedMRZRect, imageWidth: Int(cameraRect.width), imageHeight: Int(cameraRect.height))
        let scanningStream = MRZScanner.scanLive(
            imageStream: camera.imageStream,
            configuration: .init(orientation: .up, regionOfInterest: roi, minimumTextHeight: 0.1, recognitionLevel: .fast)
        )

        scanningTask = Task {
            for try await liveScanningResult in scanningStream {
                Task { @MainActor in
                    switch liveScanningResult {
                    case .found(let scanningResult):
                        boundingRects = correctBoundingRects(to: .center, rects: scanningResult.boundingRects)
                        mrzResult = scanningResult.result
                        scanningTask?.cancel()
                    case .notFound(let boundingRects):
                        self.boundingRects = correctBoundingRects(to: .center, rects: boundingRects)
                    }
                }
            }
        }
    }

    // MARK: - Correct CGRect origin from top left to center

    enum CorrectionType {
        case center
        case leftTop
    }

    private func correctBoundingRects(to type: CorrectionType, rects: ScanedBoundingRects) -> ScanedBoundingRects {
        guard let mrzRect else { fatalError("Camera rect must be set") }

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
