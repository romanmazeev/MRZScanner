//
//  ViewModel.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

import AVFoundation
import CoreImage
import MRZScanner
import Observation
import Vision
import SwiftUI

@MainActor
@Observable
final class ViewModel {
    private let camera = Camera()

    var captureSession: AVCaptureSession?
    var boundingRects: ScannedBoundingRects?
    var result: Result<ParserResult, Error>?

    private var scanningTask: Task<Void, Never>?
    private var lastScanParams: (cameraRect: CGRect, orientation: InterfaceOrientation, isVideoMirrored: Bool)?

    func startCamera() async {
        guard await camera.checkAuthorization() else { return }
        do {
            captureSession = try await camera.start()
        } catch {
            result = .failure(error)
        }
    }

    func startScanning(cameraRect: CGRect, orientation: InterfaceOrientation, isVideoMirrored: Bool) {
        lastScanParams = (cameraRect, orientation, isVideoMirrored)
        scanningTask?.cancel()
        scanningTask = Task {
            do {
                let imageStream = try camera.getImageStream()
                let cgOrientation = orientation.cgImagePropertyOrientation
                let scanner = Scanner()

                for try await image in imageStream {
                    if Task.isCancelled { break }

                    let context = ScanContext(
                        image: image,
                        cameraRect: cameraRect,
                        orientation: cgOrientation,
                        isPreviewMirrored: isVideoMirrored
                    )

                    let scanResult = try await scanner.scanFrame(
                        image: image,
                        configuration: .init(
                            orientation: cgOrientation,
                            regionOfInterest: context.normalizedROI,
                            minimumTextHeight: 0.005,
                            recognitionLevel: .fast
                        )
                    )

                    boundingRects = ScannedBoundingRects(
                        valid: scanResult.boundingRects.valid.map(context.processBoundingRect),
                        invalid: scanResult.boundingRects.invalid.map(context.processBoundingRect)
                    )

                    if let bestResult = scanResult.best(repetitions: 5) {
                        result = .success(bestResult)
                        boundingRects = nil
                        return
                    }
                }
            } catch {
                if !Task.isCancelled {
                    result = .failure(error)
                }
            }
        }
    }

    func restartScanning() {
        guard let params = lastScanParams else { return }
        startScanning(cameraRect: params.cameraRect, orientation: params.orientation, isVideoMirrored: params.isVideoMirrored)
    }
}

// MARK: - Scan Context

private struct ScanContext {
    let normalizedROI: CGRect
    let transform: AspectFillTransform
    let imageSize: CGSize
    let fullScreenHeight: CGFloat
    let fullScreenWidth: CGFloat
    let orientation: CGImagePropertyOrientation
    let isPreviewMirrored: Bool

    init(image: CIImage, cameraRect: CGRect, orientation: CGImagePropertyOrientation, isPreviewMirrored: Bool) {
        let imageSize = image.extent.size
        let fullScreenSize = CGSize(width: cameraRect.width, height: cameraRect.height)
        let transform = AspectFillTransform(imageSize: imageSize, fullScreenSize: fullScreenSize, orientation: orientation)

        let scanArea = CGRect(x: 0, y: 0, width: cameraRect.width, height: cameraRect.height)
        let roiInImagePixels = transform.viewToImage(scanArea)

        let normalizedROI = VNNormalizedRectForImageRect(
            CGRect(
                x: roiInImagePixels.origin.x,
                y: imageSize.height - roiInImagePixels.origin.y - roiInImagePixels.height,
                width: roiInImagePixels.width,
                height: roiInImagePixels.height
            ),
            Int(imageSize.width),
            Int(imageSize.height)
        )

        self.normalizedROI = normalizedROI
        self.transform = transform
        self.imageSize = imageSize
        self.fullScreenHeight = fullScreenSize.height
        self.fullScreenWidth = fullScreenSize.width
        self.orientation = orientation
        self.isPreviewMirrored = isPreviewMirrored
    }

    func processBoundingRect(_ normalizedRect: CGRect) -> CGRect {
        let isPortrait = orientation == .left || orientation == .leftMirrored ||
                         orientation == .right || orientation == .rightMirrored

        let size = isPortrait ?
            CGSize(width: imageSize.height, height: imageSize.width) :
            CGSize(width: imageSize.width, height: imageSize.height)

        let imagePixelRect = VNImageRectForNormalizedRectUsingRegionOfInterest(
            normalizedRect,
            Int(size.width),
            Int(size.height),
            normalizedROI
        )

        let globalViewRect = transform.imageToView(imagePixelRect)

        let convertedRect = orientation.convertCoordinateSystem(
            globalViewRect,
            to: .top,
            containerHeight: fullScreenHeight
        )

        if isPreviewMirrored {
            return CGRect(
                x: fullScreenWidth - convertedRect.origin.x - convertedRect.width,
                y: convertedRect.origin.y,
                width: convertedRect.width,
                height: convertedRect.height
            )
        }

        return convertedRect
    }
}

// MARK: - AspectFillTransform

private struct AspectFillTransform {
    private let scale: CGFloat
    private let xOffset: CGFloat
    private let yOffset: CGFloat
    private let orientation: CGImagePropertyOrientation

    init(imageSize: CGSize, fullScreenSize: CGSize, orientation: CGImagePropertyOrientation = .right) {
        self.orientation = orientation

        let width = (orientation == .right || orientation == .left) ? imageSize.height : imageSize.width
        let height = (orientation == .right || orientation == .left) ? imageSize.width : imageSize.height

        let viewAspectRatio = fullScreenSize.width / fullScreenSize.height
        let imageAspectRatio = width / height

        if imageAspectRatio > viewAspectRatio {
            self.scale = fullScreenSize.height / height
            let scaledImageWidth = width * scale
            self.xOffset = (scaledImageWidth - fullScreenSize.width) / 2
            self.yOffset = 0
        } else {
            self.scale = fullScreenSize.width / width
            let scaledImageHeight = height * scale
            self.xOffset = 0
            self.yOffset = (scaledImageHeight - fullScreenSize.height) / 2
        }
    }

    func viewToImage(_ rect: CGRect) -> CGRect {
        orientation.transformViewToImage(rect: rect, scale: scale, xOffset: xOffset, yOffset: yOffset)
    }

    func imageToView(_ rect: CGRect) -> CGRect {
        orientation.transformImageToView(rect: rect, scale: scale, xOffset: xOffset, yOffset: yOffset)
    }
}

// MARK: - CGImagePropertyOrientation Coordinate Transforms

private enum CoordinateSystem { case top, bottom }

private extension CGImagePropertyOrientation {
    func transformViewToImage(rect: CGRect, scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat) -> CGRect {
        switch self {
        case .right:
            return CGRect(
                x: (rect.origin.y + yOffset) / scale,
                y: (rect.origin.x + xOffset) / scale,
                width: rect.height / scale,
                height: rect.width / scale
            )
        case .left:
            return CGRect(
                x: ((rect.size.height - rect.origin.y) + yOffset) / scale,
                y: ((rect.size.width - rect.origin.x) + xOffset) / scale,
                width: rect.height / scale,
                height: rect.width / scale
            )
        default:
            return CGRect(
                x: (rect.origin.x + xOffset) / scale,
                y: (rect.origin.y + yOffset) / scale,
                width: rect.width / scale,
                height: rect.height / scale
            )
        }
    }

    func transformImageToView(rect: CGRect, scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat) -> CGRect {
        switch self {
        case .right, .left:
            return CGRect(
                x: rect.origin.y * scale - yOffset,
                y: rect.origin.x * scale - xOffset,
                width: rect.height * scale,
                height: rect.width * scale
            )
        default:
            return CGRect(
                x: rect.origin.x * scale - xOffset,
                y: rect.origin.y * scale - yOffset,
                width: rect.width * scale,
                height: rect.height * scale
            )
        }
    }

    func convertCoordinateSystem(_ rect: CGRect, to target: CoordinateSystem, containerHeight: CGFloat) -> CGRect {
        switch (target, self) {
        case (.top, .right):
            return CGRect(
                x: rect.origin.y,
                y: containerHeight - rect.origin.x - rect.width,
                width: rect.height,
                height: rect.width
            )
        case (.top, .left):
            return CGRect(
                x: containerHeight - rect.origin.y - rect.height,
                y: rect.origin.x,
                width: rect.height,
                height: rect.width
            )
        case (.top, _):
            return CGRect(
                x: rect.origin.x,
                y: containerHeight - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )
        case (.bottom, .right):
            return CGRect(
                x: rect.origin.y,
                y: rect.origin.x,
                width: rect.height,
                height: rect.width
            )
        case (.bottom, .left):
            return CGRect(
                x: containerHeight - rect.origin.y - rect.height,
                y: containerHeight - rect.origin.x - rect.width,
                width: rect.height,
                height: rect.width
            )
        case (.bottom, _):
            return rect
        }
    }
}
