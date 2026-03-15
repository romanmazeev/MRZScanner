//
//  Camera.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

@preconcurrency import AVFoundation
import CoreImage
import ConcurrencyExtras
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

final class Camera: Sendable {
    enum CameraError: Error {
        case noCaptureDeviceAvailable
        case unableToAddVideoInput
        case unableToAddVideoOutput
        case cameraNotStarted
    }

    private let captureSessionStorage: LockIsolated<AVCaptureSession?> = .init(nil)
    private let bufferDelegate: LockIsolated<OutputSampleBufferDelegate?> = .init(nil)

    @MainActor
    func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined, .restricted:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied:
#if canImport(UIKit)
            if let appSettings = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(appSettings) {
                await UIApplication.shared.open(appSettings)
            }
#endif
#if canImport(AppKit)
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                NSWorkspace.shared.open(url)
            }
#endif
            return false
        @unknown default:
            return false
        }
    }

    func start() async throws -> AVCaptureSession {
        if let existing = captureSessionStorage.value {
            return existing
        }

        let session = AVCaptureSession()
        let outputSampleBufferDelegate = OutputSampleBufferDelegate()

        session.beginConfiguration()

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            throw CameraError.noCaptureDeviceAvailable
        }
        let deviceInput = try AVCaptureDeviceInput(device: captureDevice)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(
            outputSampleBufferDelegate,
            queue: .init(label: "com.MRZScannerExample.OutputSampleBufferDelegate")
        )

        guard session.canAddInput(deviceInput) else {
            throw CameraError.unableToAddVideoInput
        }

        guard session.canAddOutput(videoOutput) else {
            throw CameraError.unableToAddVideoOutput
        }

        session.addInput(deviceInput)
        session.addOutput(videoOutput)

        captureSessionStorage.setValue(session)
        bufferDelegate.setValue(outputSampleBufferDelegate)

        session.commitConfiguration()
        if !session.isRunning {
            session.startRunning()
        }

        return session
    }

    func getImageStream() throws -> AsyncStream<CIImage> {
        guard let delegate = bufferDelegate.value else {
            throw CameraError.cameraNotStarted
        }

        return AsyncStream<CIImage>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            delegate.continuation.withValue { $0 = continuation }
        }
    }

}

private final class OutputSampleBufferDelegate: NSObject, Sendable, AVCaptureVideoDataOutputSampleBufferDelegate {
    let continuation: LockIsolated<AsyncStream<CIImage>.Continuation?> = .init(nil)

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        continuation.value?.yield(CIImage(cvPixelBuffer: pixelBuffer))
    }
}
