//
//  ContentView.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

import MRZScanner
import SwiftUI

struct ContentView: View {
    private var viewModel = ViewModel()
    @State private var cameraRect: CGRect?
    @State private var orientation: InterfaceOrientation?
    @State private var isVideoMirrored = false

    var body: some View {
        ZStack {
            if let captureSession = viewModel.captureSession {
                GeometryReader { proxy in
                    CameraView(
                        captureSession: captureSession,
                        onViewDidLayoutSubviews: { mirrored in
                            let rect = proxy.frame(in: .global)
                            cameraRect = rect
                            isVideoMirrored = mirrored
                            guard let orientation else { return }
                            viewModel.startScanning(cameraRect: rect, orientation: orientation, isVideoMirrored: mirrored)
                        },
                        onOrientationChanged: { newOrientation, mirrored in
                            orientation = newOrientation
                            isVideoMirrored = mirrored
                            guard let cameraRect else { return }
                            viewModel.startScanning(cameraRect: cameraRect, orientation: newOrientation, isVideoMirrored: mirrored)
                        }
                    )
                }
            }

            if let boundingRects = viewModel.boundingRects {
                ForEach(boundingRects.valid, id: \.self) { rect in
                    createBoundingRect(rect, color: .green)
                }
                ForEach(boundingRects.invalid, id: \.self) { rect in
                    createBoundingRect(rect, color: .red)
                }
            }
        }
        .alert(isPresented: .init(
            get: { viewModel.result != nil },
            set: { _ in viewModel.result = nil }
        )) {
            Alert(
                title: Text(createAlertTitle(result: viewModel.result!)),
                message: Text(createAlertMessage(result: viewModel.result!)),
                dismissButton: .default(Text("Restart scanning")) {
                    viewModel.restartScanning()
                }
            )
        }
        .task {
            await viewModel.startCamera()
        }
#if os(iOS)
        .statusBarHidden()
#endif
        .ignoresSafeArea()
    }

    private func createBoundingRect(_ rect: CGRect, color: Color) -> some View {
        Rectangle()
            .stroke(color)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.origin.x + rect.width / 2,
                      y: rect.origin.y + rect.height / 2)
    }

    private func createAlertTitle(result: Result<ParserResult, Error>) -> String {
        switch result {
        case .success: return "Scanned successfully"
        case .failure: return "Error"
        }
    }

    private func createAlertMessage(result: Result<ParserResult, Error>) -> String {
        switch result {
        case .success(let mrzResult):
            let birthdateString = mrzResult.birthdate.formatted(date: .abbreviated, time: .omitted)
            let expiryDateString = mrzResult.expiryDate?.formatted(date: .abbreviated, time: .omitted)

            return """
                   Document type: \(mrzResult.documentType)
                   Country code: \(mrzResult.issuingCountry.identifier)
                   Surnames: \(mrzResult.name.surname)
                   Given names: \(mrzResult.name.givenNames ?? "-")
                   Document number: \(mrzResult.documentNumber)
                   Nationality: \(mrzResult.nationalityCountryCode)
                   Birthdate: \(birthdateString)
                   Sex: \(mrzResult.sex)
                   Expiry date: \(expiryDateString ?? "-")
                   Optional data: \(mrzResult.optionalData ?? "-")
                   Optional data 2: \(mrzResult.optionalData2 ?? "-")
                   """
        case .failure(let error):
            return error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
