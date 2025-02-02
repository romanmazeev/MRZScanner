//
//  Camera.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

@preconcurrency import AVFoundation
import CoreImage

actor Camera {
    nonisolated let captureSession = AVCaptureSession()
    private let outputSampleBufferDelegate = OutputSampleBufferDelegate()

    var imageStream: AsyncStream<CIImage>? {
        .init { continuation in
            outputSampleBufferDelegate.continuation = continuation
        }
    }

    func startCamera() async throws {
        guard await checkAuthorization() else {
            fatalError("You need to give access")
        }

        try await configureCaptureSession()
    }

    private func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined, .restricted, .denied:
            return await AVCaptureDevice.requestAccess(for: .video)
        @unknown default:
            return false
        }
    }

    private func configureCaptureSession() async throws {
        self.captureSession.beginConfiguration()

        defer {
            self.captureSession.commitConfiguration()
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }

        guard let captureDevice = AVCaptureDevice.default(for: .video) else { fatalError("Unable to create capture device") }
        let deviceInput = try AVCaptureDeviceInput(device: captureDevice)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(outputSampleBufferDelegate, queue: .init(label: "com.MRZScannerExample.OutputSampleBufferDelegate"))

        guard captureSession.canAddInput(deviceInput) else {
            fatalError("Unable to add device input to capture session.")
        }

        guard captureSession.canAddOutput(videoOutput) else {
            fatalError("Unable to add video output to capture session.")
        }

        captureSession.addInput(deviceInput)
        captureSession.addOutput(videoOutput)

        videoOutput.connection(with: .video)?.videoRotationAngle = 90
    }
}

final private class OutputSampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var continuation: AsyncStream<CIImage>.Continuation?

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }

        continuation?.yield(CIImage(cvPixelBuffer: pixelBuffer))
    }
}
