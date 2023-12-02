//
//  ScannerTests.swift
//
//
//  Created by Roman Mazeev on 02/12/2023.
//

import Dependencies
@testable import MRZScanner
import XCTest

final class MRZScannerTests: XCTestCase {
    private let image = CIImage(color: .blue)
    private let scanningConfiguration: ScanningConfiguration = .mock()
    private let textRecognizerResults: [TextRecognizer.Result] = [.init(results: ["test"], boundingRect: .zero)]
    private let validatorResults: [Validator.Result] = [.init(result: "test", index: 0)]
    private let boundingRectConverterResults: ScannedBoundingRects = .init(valid: [.init(), .init()], invalid: [.init()])
    private let parserResult: ParserResult = .mock
    private let trackerResult: TrackerResult = [.mock: 1]

    var validatorMock: Validator {
        Validator { possibleLines in
            XCTAssertEqual(self.textRecognizerResults.map(\.results), possibleLines)
            return self.validatorResults
        }
    }

    var boundingRectConverterMock: BoundingRectConverter {
        BoundingRectConverter { results, validLines in
            XCTAssertEqual(results, self.textRecognizerResults)
            XCTAssertEqual(validLines, self.validatorResults)
            return self.boundingRectConverterResults
        }
    }

    func testSingleImageSuccess() throws {
        let textRecognizerMock = TextRecognizer { configuration, scanningImage in
            XCTAssertEqual(self.image, scanningImage)
            XCTAssertEqual(self.scanningConfiguration, configuration)

            return self.textRecognizerResults
        }

        let parser = Parser { mrzLines in
            XCTAssertEqual(mrzLines, self.validatorResults.map(\.result))
            return self.parserResult
        }

        let scanningExpectation = expectation(description: "scanning")
        Task {
            await withDependencies {
                $0.textRecognizer = textRecognizerMock
                $0.validator = validatorMock
                $0.boundingRectConverter = boundingRectConverterMock
                $0.parser = parser
            } operation: {
                do {
                    let currentResult = try await image.scanForMRZCode(configuration: scanningConfiguration)
                    XCTAssertEqual(currentResult.results, parserResult)
                    XCTAssertEqual(currentResult.boundingRects, boundingRectConverterResults)
                } catch {
                    XCTFail("Should not fail here. Error: \(error.localizedDescription)")
                }

                scanningExpectation.fulfill()
            }
        }

        wait(for: [scanningExpectation], timeout: 10)
    }

    func testSingleImageParserFailure() throws {
        let textRecognizerMock = TextRecognizer { configuration, scanningImage in
            XCTAssertEqual(self.image, scanningImage)
            XCTAssertEqual(self.scanningConfiguration, configuration)

            return self.textRecognizerResults
        }

        let parser = Parser { mrzLines in
            XCTAssertEqual(mrzLines, self.validatorResults.map(\.result))
            return nil
        }

        let scanningExpectation = expectation(description: "scanning")
        Task {
            try await withDependencies {
                $0.textRecognizer = textRecognizerMock
                $0.validator = validatorMock
                $0.boundingRectConverter = boundingRectConverterMock
                $0.parser = parser
            } operation: {
                do {
                    _ = try await image.scanForMRZCode(configuration: scanningConfiguration)
                    XCTFail("Should fail here")
                } catch {
                    XCTAssert(try XCTUnwrap(error as? CIImage.ScanningError) == .codeNotFound)
                }
                scanningExpectation.fulfill()
            }
        }

        wait(for: [scanningExpectation], timeout: 10)
    }

    func testSingleImageTextRecognizerFailure() throws {
        let textRecognizerMock = TextRecognizer { configuration, scanningImage in
            XCTAssertEqual(self.image, scanningImage)
            XCTAssertEqual(self.scanningConfiguration, configuration)

            throw CIImage.ScanningError.codeNotFound
        }

        let scanningExpectation = expectation(description: "scanning")
        Task {
            try await withDependencies {
                $0.textRecognizer = textRecognizerMock
            } operation: {
                do {
                    _ = try await image.scanForMRZCode(configuration: scanningConfiguration)
                    XCTFail("Should fail here")
                } catch {
                    XCTAssert(try XCTUnwrap(error as? CIImage.ScanningError) == .codeNotFound)
                }
                scanningExpectation.fulfill()
            }
        }

        wait(for: [scanningExpectation], timeout: 10)
    }

    func testImageStreamSuccess() {
        let textRecognizerMock = TextRecognizer { configuration, scanningImage in
            XCTAssertEqual(self.image, scanningImage)
            XCTAssertEqual(self.scanningConfiguration, configuration)

            return self.textRecognizerResults
        }

        let parser = Parser { mrzLines in
            XCTAssertEqual(mrzLines, self.validatorResults.map(\.result))
            return self.parserResult
        }

        let tracker = Tracker { _, result in
            XCTAssertEqual(result, self.parserResult)
            return self.trackerResult
        }

        let scanningExpectation = expectation(description: "scanning")
        Task {
            await withDependencies {
                $0.textRecognizer = textRecognizerMock
                $0.validator = validatorMock
                $0.boundingRectConverter = boundingRectConverterMock
                $0.parser = parser
                $0.tracker = tracker
            } operation: {
                let resultsStream = AsyncStream<CIImage> { continuation in
                    continuation.yield(image)
                    continuation.finish()
                }
                    .scanForMRZCode(configuration: scanningConfiguration)

                do {
                    for try await liveScanningResult in resultsStream {
                        XCTAssertEqual(liveScanningResult.results, trackerResult)
                        XCTAssertEqual(liveScanningResult.boundingRects, boundingRectConverterResults)
                        scanningExpectation.fulfill()
                    }
                } catch {
                    XCTFail("Should not fail here. Error: \(error)")
                }
            }
        }

        wait(for: [scanningExpectation], timeout: 10)
    }


    func testImageStreamParsingFailure() throws {
        let textRecognizerMock = TextRecognizer { configuration, scanningImage in
            XCTAssertEqual(self.image, scanningImage)
            XCTAssertEqual(self.scanningConfiguration, configuration)

            return self.textRecognizerResults
        }

        let parser = Parser { mrzLines in
            XCTAssertEqual(mrzLines, self.validatorResults.map(\.result))
            return nil
        }

        let scanningExpectation = expectation(description: "scanning")
        Task {
            await withDependencies {
                $0.textRecognizer = textRecognizerMock
                $0.validator = validatorMock
                $0.boundingRectConverter = boundingRectConverterMock
                $0.parser = parser
            } operation: {
                let resultsStream = AsyncStream<CIImage> { continuation in
                    continuation.yield(image)
                    continuation.finish()
                }
                    .scanForMRZCode(configuration: scanningConfiguration)

                do {
                    for try await liveScanningResult in resultsStream {
                        XCTAssertEqual(liveScanningResult.results, [:])
                        XCTAssertEqual(liveScanningResult.boundingRects, boundingRectConverterResults)
                        scanningExpectation.fulfill()
                    }
                } catch {
                    XCTFail("Should not fail here. Error: \(error)")
                }
            }
        }

        wait(for: [scanningExpectation], timeout: 10)
    }

    func testImageStreamTextRecognizerFailure() throws {
        let textRecognizerMock = TextRecognizer { configuration, scanningImage in
            XCTAssertEqual(self.image, scanningImage)
            XCTAssertEqual(self.scanningConfiguration, configuration)

            throw CIImage.ScanningError.codeNotFound
        }

        let scanningExpectation = expectation(description: "scanning")
        Task {
            try await withDependencies {
                $0.textRecognizer = textRecognizerMock
            } operation: {
                let resultsStream = AsyncStream<CIImage> { continuation in
                    continuation.yield(image)
                    continuation.finish()
                }
                    .scanForMRZCode(configuration: scanningConfiguration)

                do {
                    for try await _ in resultsStream {}
                } catch {
                    let error = try XCTUnwrap(error as? CIImage.ScanningError)
                    XCTAssertEqual(error, .codeNotFound)
                    scanningExpectation.fulfill()
                }
            }
        }

        wait(for: [scanningExpectation], timeout: 10)
    }
}
