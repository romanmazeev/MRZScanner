//
//  Camera.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

import AVFoundation
import CoreImage

final class Camera: NSObject {
    let captureSession = AVCaptureSession()

    private(set) lazy var imageStream: AsyncStream<CIImage> = {
        AsyncStream { continuation in
            imageStreamCallback = { ciImage in
                continuation.yield(ciImage)
            }
        }
    }()
    private var imageStreamCallback: ((CIImage) -> Void)?

    private let captureDevice = AVCaptureDevice.default(for: .video)
    private let sessionQueue = DispatchQueue(label: "Session queue")
    private var isCaptureSessionConfigured = false
    private var deviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?

    func start() async {
        let authorized = await checkAuthorization()
        guard authorized else {
            fatalError("You need to give access")
        }

        if isCaptureSessionConfigured {
            if !captureSession.isRunning {
                sessionQueue.async { [self] in
                    self.captureSession.startRunning()
                }
            }
            return
        }

        sessionQueue.async { [self] in
            try? self.configureCaptureSession { success in
                guard success else { return }
                self.captureSession.startRunning()
            }
        }
    }

    private func checkAuthorization() async -> Bool {
        func requestCameraAccess() async -> Bool {
            sessionQueue.suspend()
            let status = await AVCaptureDevice.requestAccess(for: .video)
            sessionQueue.resume()
            return status
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined, .restricted, .denied:
            return await requestCameraAccess()
        @unknown default:
            return false
        }
    }

    private func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) throws {
        var success = false

        self.captureSession.beginConfiguration()

        defer {
            self.captureSession.commitConfiguration()
            completionHandler(success)
        }

        guard let captureDevice else { fatalError("Unable to create capture device") }
        let deviceInput = try AVCaptureDeviceInput(device: captureDevice)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: .init(label: "VideoDataOutput queue"))

        guard captureSession.canAddInput(deviceInput) else {
            fatalError("Unable to add device input to capture session.")
        }

        guard captureSession.canAddOutput(videoOutput) else {
            fatalError("Unable to add video output to capture session.")
        }

        captureSession.addInput(deviceInput)
        captureSession.addOutput(videoOutput)

        self.deviceInput = deviceInput
        self.videoOutput = videoOutput

        videoOutput.connection(with: .video)?.videoOrientation = .portrait

        isCaptureSessionConfigured = true

        success = true
    }
}

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }

        imageStreamCallback?(CIImage(cvPixelBuffer: pixelBuffer))
    }
}
