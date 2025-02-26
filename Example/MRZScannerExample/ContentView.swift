//
//  ContentView.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

import MRZScanner
import SwiftUI

struct ContentView: View {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    @StateObject private var viewModel = ViewModel()
    @State private var mrzRect: CGRect?

    var body: some View {
        GeometryReader { proxy in
            Group {
                CameraView(captureSession: viewModel.captureSession)

                ZStack {
                    Color.black.opacity(0.5)

                    if let mrzRect {
                        Rectangle()
                            .blendMode(.destinationOut)
                            .frame(width: mrzRect.width, height: mrzRect.height)
                            .position(x: mrzRect.origin.x + mrzRect.width / 2,
                                      y: mrzRect.origin.y + mrzRect.height / 2)
                            .task {
                                await viewModel.startMRZScanning(mrzRect: mrzRect)
                            }
                    }
                }
                .compositingGroup()

                if let boundingRects = viewModel.boundingRects {
                    ForEach(boundingRects.valid, id: \.self) { boundingRect in
                        createBoundingRect(boundingRect, color: .green)
                    }

                    ForEach(boundingRects.invalid, id: \.self) { boundingRect in
                        createBoundingRect(boundingRect, color: .red)
                    }
                }
            }
            .onAppear {
                let cameraRect = proxy.frame(in: .global)

                let mrzRectWidth = cameraRect.width - 40
                let mrzRectHeight: CGFloat = 65
                let mrzRect = CGRect(
                    x: (cameraRect.width - mrzRectWidth) / 2, // Center horizontally
                    y: (cameraRect.height - mrzRectHeight) / 2, // Center vertically
                    width: mrzRectWidth,
                    height: mrzRectHeight
                )
                self.mrzRect = mrzRect

                viewModel.setContentRects(cameraRect: cameraRect, mrzRect: mrzRect)
            }
        }
        .alert(isPresented: .init(get: { viewModel.result != nil }, set: { _ in viewModel.result = nil })) {
            Alert(
                title: Text(createAlertTitle(result: viewModel.result!)),
                message: Text(createAlertMessage(result: viewModel.result!)),
                dismissButton: .default(Text("Restart scanning")) {
                    Task {
                        guard let mrzRect else { return }

                        await viewModel.startMRZScanning(mrzRect: mrzRect)
                    }
                }
            )
        }
        .task {
            await viewModel.startCamera()
        }
        .statusBarHidden()
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
        case .success:
            return "Scanned successfully"
        case .failure:
            return "Error"
        }
    }

    private func createAlertMessage(result: Result<ParserResult, Error>) -> String {
        switch result {
        case .success(let mrzResult):
            let birthdateString = dateFormatter.string(from: mrzResult.birthdate)
            let expiryDateString = mrzResult.expiryDate.map { dateFormatter.string(from: $0) }

            return """
                   Document type: \(mrzResult.documentType)
                   Country code: \(mrzResult.countryCode)
                   Surnames: \(mrzResult.names.surnames)
                   Given names: \(mrzResult.names.givenNames ?? "-")
                   Document number: \(mrzResult.documentNumber)
                   nationalityCountryCode: \(mrzResult.nationalityCountryCode)
                   birthdate: \(birthdateString)
                   sex: \(mrzResult.sex)
                   expiryDate: \(expiryDateString ?? "-")
                   personalNumber: \(mrzResult.optionalData ?? "-")
                   personalNumber2: \(mrzResult.optionalData2 ?? "-")
                   """
        case .failure(let error):
            return error.localizedDescription
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
