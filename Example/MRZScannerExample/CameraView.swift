//
//  CameraView.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

import UIKit
import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    let captureSession: AVCaptureSession

    func makeUIViewController(context: Context) -> UIViewController {
        return CameraViewController(captureSession: captureSession)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

final class CameraViewController: UIViewController {
    var previewLayer: AVCaptureVideoPreviewLayer!

    init(captureSession: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        previewLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoRotationAngle = 90
        view.layer.addSublayer(previewLayer)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(captureSession: .init())
    }
}
