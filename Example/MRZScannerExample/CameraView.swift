//
//  CameraView.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

import SwiftUI
import AVFoundation

// MARK: - InterfaceOrientation

extension InterfaceOrientation {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
#if os(macOS)
        return .up
#else
        switch self {
        case .portrait:
            return .right
        case .landscapeLeft:
            return .down
        case .portraitUpsideDown:
            return .left
        case .landscapeRight:
            return .up
        default:
            return .up
        }
#endif
    }

#if canImport(UIKit) && !os(tvOS)
    init(uiInterfaceOrientation: UIInterfaceOrientation) {
        switch uiInterfaceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        default:
            self = .portrait
        }
    }
#endif
}

// MARK: - Common Protocol

#if !os(visionOS)

@MainActor
private protocol CameraViewControllerProtocol {
    var captureSession: AVCaptureSession { get }
    var previewLayer: AVCaptureVideoPreviewLayer { get }
    var onViewDidLayoutSubviews: (Bool) -> Void { get }
    var onOrientationChanged: (InterfaceOrientation, Bool) -> Void { get }
}

private extension CameraViewControllerProtocol {
    var isVideoMirrored: Bool {
        previewLayer.connection?.isVideoMirrored ?? false
    }

    func setupPreviewLayer() {
        previewLayer.videoGravity = .resizeAspectFill
    }

    func updatePreviewLayerFrame(to bounds: CGRect) {
        previewLayer.frame = bounds
    }
}

#endif

// MARK: - SwiftUI Wrapper

struct CameraView: View {
    private let captureSession: AVCaptureSession
    private let onViewDidLayoutSubviews: (Bool) -> Void
    private let onOrientationChanged: (InterfaceOrientation, Bool) -> Void

    init(
        captureSession: AVCaptureSession,
        onViewDidLayoutSubviews: @escaping (Bool) -> Void = { _ in },
        onOrientationChanged: @escaping (InterfaceOrientation, Bool) -> Void = { _, _ in }
    ) {
        self.captureSession = captureSession
        self.onViewDidLayoutSubviews = onViewDidLayoutSubviews
        self.onOrientationChanged = onOrientationChanged
    }

    var body: some View {
#if canImport(AppKit)
        CameraNSViewRepresentable(
            captureSession: captureSession,
            onViewDidLayoutSubviews: onViewDidLayoutSubviews,
            onOrientationChanged: onOrientationChanged
        )
#endif
#if os(iOS)
        CameraUIViewControllerRepresentable(
            captureSession: captureSession,
            onViewDidLayoutSubviews: onViewDidLayoutSubviews,
            onOrientationChanged: onOrientationChanged
        )
#endif
    }
}

// MARK: - iOS Implementation

#if os(iOS)

private struct CameraUIViewControllerRepresentable: UIViewControllerRepresentable {
    let captureSession: AVCaptureSession
    let onViewDidLayoutSubviews: (Bool) -> Void
    let onOrientationChanged: (InterfaceOrientation, Bool) -> Void

    func makeUIViewController(context: Context) -> CameraUIViewController {
        CameraUIViewController(
            captureSession: captureSession,
            onViewDidLayoutSubviews: onViewDidLayoutSubviews,
            onOrientationChanged: onOrientationChanged
        )
    }

    func updateUIViewController(_ uiViewController: CameraUIViewController, context: Context) {}
}

final class CameraUIViewController: UIViewController, CameraViewControllerProtocol {
    let captureSession: AVCaptureSession
    let previewLayer: AVCaptureVideoPreviewLayer
    let onViewDidLayoutSubviews: (Bool) -> Void
    let onOrientationChanged: (InterfaceOrientation, Bool) -> Void

    init(
        captureSession: AVCaptureSession,
        onViewDidLayoutSubviews: @escaping (Bool) -> Void,
        onOrientationChanged: @escaping (InterfaceOrientation, Bool) -> Void
    ) {
        self.captureSession = captureSession
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.onViewDidLayoutSubviews = onViewDidLayoutSubviews
        self.onOrientationChanged = onOrientationChanged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updatePreviewOrientation()
        view.layer.addSublayer(previewLayer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreviewLayerFrame(to: view.bounds)
        onViewDidLayoutSubviews(isVideoMirrored)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.updatePreviewOrientation()
        })
    }

    private func updatePreviewOrientation() {
        guard let connection = previewLayer.connection else { return }
        let orientation = getCurrentOrientation()
        let rotationAngle = calculateRotationAngle(for: orientation)
        if connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        }
        onOrientationChanged(.init(uiInterfaceOrientation: orientation), isVideoMirrored)
    }

    private func getCurrentOrientation() -> UIInterfaceOrientation {
        view.window?.windowScene?.effectiveGeometry.interfaceOrientation ?? .portrait
    }

    private func calculateRotationAngle(for orientation: UIInterfaceOrientation) -> CGFloat {
        switch orientation {
        case .portrait: return 90
        case .landscapeLeft: return 180
        case .portraitUpsideDown: return 270
        case .landscapeRight: return 0
        default: return 90
        }
    }
}

#endif

// MARK: - macOS Implementation

#if canImport(AppKit)

private struct CameraNSViewRepresentable: NSViewControllerRepresentable {
    let captureSession: AVCaptureSession
    let onViewDidLayoutSubviews: (Bool) -> Void
    let onOrientationChanged: (InterfaceOrientation, Bool) -> Void

    func makeNSViewController(context: Context) -> CameraNSViewController {
        CameraNSViewController(
            captureSession: captureSession,
            onViewDidLayoutSubviews: onViewDidLayoutSubviews,
            onOrientationChanged: onOrientationChanged
        )
    }

    func updateNSViewController(_ nsView: CameraNSViewController, context: Context) {}
}

final class CameraNSViewController: NSViewController, CameraViewControllerProtocol {
    let captureSession: AVCaptureSession
    let previewLayer: AVCaptureVideoPreviewLayer
    let onViewDidLayoutSubviews: (Bool) -> Void
    let onOrientationChanged: (InterfaceOrientation, Bool) -> Void

    init(
        captureSession: AVCaptureSession,
        onViewDidLayoutSubviews: @escaping (Bool) -> Void,
        onOrientationChanged: @escaping (InterfaceOrientation, Bool) -> Void
    ) {
        self.captureSession = captureSession
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.onViewDidLayoutSubviews = onViewDidLayoutSubviews
        self.onOrientationChanged = onOrientationChanged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
        view.wantsLayer = true
        view.layer?.addSublayer(previewLayer)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        onOrientationChanged(.portrait, isVideoMirrored)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        updatePreviewLayerFrame(to: view.bounds)
        onViewDidLayoutSubviews(isVideoMirrored)
    }
}

#endif
