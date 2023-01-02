//
//  ContentView.swift
//  Example
//
//  Created by Roman Mazeev on 01/01/2023.
//

import SwiftUI
import MRZParser

struct ContentView: View {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        GeometryReader { proxy in
            Group {
                if let cameraRect = viewModel.cameraRect {
                    CameraView(captureSession: viewModel.captureSession)
                        .frame(width: cameraRect.width, height: cameraRect.height)
                }

                ZStack {
                    Color.black.opacity(0.5)

                    if let mrzRect = viewModel.mrzRect {
                        Rectangle()
                            .blendMode(.destinationOut)
                            .frame(width: mrzRect.size.width, height: mrzRect.size.height)
                            .position(mrzRect.origin)
                            .task {
                                do {
                                    try await viewModel.startMRZScanning()
                                } catch {
                                    print(error.localizedDescription)
                                }
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
                viewModel.cameraRect = proxy.frame(in: .global)
                viewModel.mrzRect = .init(origin: .init(x: proxy.size.width / 2, y: proxy.size.height / 2),
                                          size: .init(width: proxy.size.width - 40, height: proxy.size.width / 5))
            }
        }
        .alert(isPresented: .init(get: { viewModel.mrzResult != nil }, set: { _ in viewModel.mrzResult = nil })) {
            Alert(
                title: Text("Important message"),
                message: Text(createAlertMessage(mrzResult: viewModel.mrzResult!)),
                dismissButton: .default(Text("Got it!")) {
                    Task {
                        try await viewModel.startMRZScanning()
                    }
                }
            )
        }
        .task {
            viewModel.startCamera()
        }
        .statusBarHidden()
        .ignoresSafeArea()
    }

    private func createBoundingRect(_ rect: CGRect, color: Color) -> some View {
        Rectangle()
            .stroke(color)
            .frame(width: rect.width, height: rect.height)
            .position(rect.origin)
    }

    private func createAlertMessage(mrzResult: MRZResult) -> String {
        var birthdateString: String?
        var expiryDateString: String?

        if let birthdate = mrzResult.birthdate {
            birthdateString = dateFormatter.string(from: birthdate)
        }

        if let expiryDate = mrzResult.expiryDate {
            expiryDateString = dateFormatter.string(from: expiryDate)
        }

        return """
               Document type: \(mrzResult.documentType)
               Country code: \(mrzResult.countryCode)
               Surnames: \(mrzResult.surnames)
               Given names: \(mrzResult.givenNames)
               Document number: \(mrzResult.documentNumber ?? "-")
               nationalityCountryCode: \(mrzResult.nationalityCountryCode)
               birthdate: \(birthdateString ?? "-")
               sex: \(mrzResult.sex)
               expiryDate: \(expiryDateString ?? "-")
               personalNumber: \(mrzResult.optionalData ?? "-")
               personalNumber2: \(mrzResult.optionalData2 ?? "-")
               """
    }
}

extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
