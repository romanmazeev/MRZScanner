//
//  TextRecognizerTests.swift
//  
//
//  Created by Roman Mazeev on 02/12/2023.
//

@testable import MRZScanner
import CoreImage
import XCTest

final class TextRecognizerTests: XCTestCase {
    func testScanImageSuccess() async throws {
        let fileURL = try XCTUnwrap(Bundle.module.url(forResource: "TestImage", withExtension: "png"))
        let imageData = try Data(contentsOf: fileURL)
        let image = try XCTUnwrap(CIImage(data: imageData))

        let result = try await TextRecognizer.liveValue.recognize(.mock(), image)
        XCTAssertEqual(result,  [
            .init(results: ["Red Green Purple"], boundingRect: .init(x: 0.1296875, y: 0.7222222222222222, width: 0.75, height: 0.13636363636363635)),
            .init(results: ["Brown Blue Red"], boundingRect: .init(x: 0.1625, y: 0.6035353535353536, width: 0.6843750000000001, height: 0.10353535353535348)),
            .init(results: ["Purple Red Brown"], boundingRect: .init(x: 0.1203125, y: 0.2752525252525253, width: 0.7687499999999999, height: 0.13636363636363635)),
            .init(results: ["Red Green Blue"], boundingRect: .init(x: 0.171875, y: 0.15656565656565657, width: 0.665625, height: 0.10606060606060608))
        ])
    }

    func testScanImageFailedZeroDimensionedImage() async {
        do {
            _ = try await TextRecognizer.liveValue.recognize(.mock(), CIImage())
            XCTFail("Should fail here")
        } catch {
            XCTAssertEqual(error.localizedDescription, "CRImage Reader Detector was given zero-dimensioned image (0 x 0)")
        }
    }

    func testScanImageFailedWrongROI() async {
        do {
            _ = try await TextRecognizer.liveValue.recognize(.mock(roi: .init(x: 0, y: 0, width: 200, height: 200)), CIImage())
            XCTFail("Should fail here")
        } catch {
            XCTAssertEqual(error.localizedDescription, "The region of interest [0, 0, 200, 200] is not within the normalized bounds of [0 0 1 1]")
        }
    }
}

extension TextRecognizer.Result: @retroactive Equatable {
    public static func == (lhs: TextRecognizer.Result, rhs: TextRecognizer.Result) -> Bool {
        lhs.results == rhs.results &&
        lhs.boundingRect == rhs.boundingRect
    }
}
