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
    @State private var cameraRect: CGRect?
    @State private var mrzRect: CGRect?

    var body: some View {
        GeometryReader { proxy in
            Group {
                if let cameraRect {
                    CameraView(captureSession: viewModel.captureSession)
                        .frame(width: cameraRect.width, height: cameraRect.height)
                }

                ZStack {
                    Color.black.opacity(0.5)

                    if let mrzRect {
                        Rectangle()
                            .blendMode(.destinationOut)
                            .frame(width: mrzRect.size.width, height: mrzRect.size.height)
                            .position(mrzRect.origin)
                            .task {
                                guard let cameraRect else { return }

                                await viewModel.startMRZScanning(cameraRect: cameraRect, mrzRect: mrzRect)
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
                cameraRect = proxy.frame(in: .global)
                mrzRect = .init(origin: .init(x: proxy.size.width / 2, y: proxy.size.height / 2),
                                size: .init(width: proxy.size.width - 40, height: proxy.size.width / 5))
            }
        }
        .alert(isPresented: .init(get: { viewModel.result != nil }, set: { _ in viewModel.result = nil })) {
            Alert(
                title: Text(createAlertTitle(result: viewModel.result!)),
                message: Text(createAlertMessage(result: viewModel.result!))
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
            .position(rect.origin)
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
        case .failure(let error):
            return error.localizedDescription
        }
    }
}

extension CGRect: @retroactive Hashable {
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
