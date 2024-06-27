//
//  ScannerTests.swift
//
//
//  Created by Roman Mazeev on 02/12/2023.
//

import CustomDump
import Dependencies
@testable import MRZScanner
@preconcurrency import CoreImage
import XCTest

final class MRZScannerTests: XCTestCase {
    private enum Event: Equatable, Sendable {
        case recognize(ScanningConfiguration, Int)
        case getValidatedResults([[String]])
        case convert([TextRecognizer.Result], [Validator.Result])
        case parse([String])

        case currentResults
        case track(ParserResult)
    }

    func testSingleImageSuccess() async throws {
        let events = LockIsolated([Event]())

        try await withDependencies {
            $0.textRecognizer.recognize = { @Sendable configuration, scanningImage in
                events.withValue { $0.append(.recognize(configuration,scanningImage.base64EncodedString.count)) }
                return [.mock]
            }
            $0.validator.getValidatedResults = { @Sendable possibleLines in
                events.withValue { $0.append(.getValidatedResults(possibleLines)) }
                return [.mock]
            }
            $0.boundingRectConverter.convert = { @Sendable results, validLines in
                events.withValue { $0.append(.convert(results, validLines)) }
                return .mock
            }
            $0.parser.parse = { @Sendable mrzLines in
                events.withValue { $0.append(.parse(mrzLines)) }
                return .mock
            }
        } operation: {
            let currentResult = try await XCTUnwrap(CIImage(data: .imageMock)).scanForMRZCode(configuration: .mock())
            XCTAssertEqual(currentResult.results, .mock)
            XCTAssertEqual(currentResult.boundingRects, .mock)
        }

        XCTAssertNoDifference(
            events.value,
            [
                .recognize(.mock(), 1348268),
                .getValidatedResults([["test"]]),
                .parse(["test"]),
                .convert([.mock], [.mock]),
            ]
        )
    }

    func testSingleImageParserFailure() async throws {
        let events = LockIsolated([Event]())

        try await withDependencies {
            $0.textRecognizer.recognize = { @Sendable configuration, scanningImage in
                events.withValue { $0.append(.recognize(configuration, scanningImage.base64EncodedString.count)) }
                return [.mock]
            }
            $0.validator.getValidatedResults = { @Sendable possibleLines in
                events.withValue { $0.append(.getValidatedResults(possibleLines)) }
                return [.mock]
            }
            $0.boundingRectConverter.convert = { @Sendable results, validLines in
                events.withValue { $0.append(.convert(results, validLines)) }
                return .mock
            }
            $0.parser.parse = { @Sendable mrzLines in
                events.withValue { $0.append(.parse(mrzLines)) }
                return nil
            }
        } operation: {
            do {
                _ = try await XCTUnwrap(CIImage(data: .imageMock)).scanForMRZCode(configuration: .mock())
                XCTFail("Should fail here")
            } catch {
                XCTAssertEqual(try XCTUnwrap(error as? CIImage.ScanningError), .codeNotFound)
            }
        }

        XCTAssertNoDifference(
            events.value,
            [
                .recognize(.mock(), 1348268),
                .getValidatedResults([["test"]]),
                .parse(["test"]),
                .convert([.mock], [.mock])
            ]
        )
    }

    func testSingleImageTextRecognizerFailure() async throws {
        let events = LockIsolated([Event]())

        try await withDependencies {
            $0.textRecognizer.recognize = { @Sendable configuration, scanningImage in
                events.withValue { $0.append(.recognize(configuration, scanningImage.base64EncodedString.count)) }
                throw CIImage.ScanningError.codeNotFound
            }
        } operation: {
            do {
                _ = try await XCTUnwrap(CIImage(data: .imageMock)).scanForMRZCode(configuration: .mock())
                XCTFail("Should fail here")
            } catch {
                XCTAssertEqual(try XCTUnwrap(error as? CIImage.ScanningError), .codeNotFound)
            }
        }

        XCTAssertNoDifference(
            events.value,
            [
                .recognize(.mock(), 1348268)
            ]
        )
    }

    func testImageStreamSuccess() async throws {
        let events = LockIsolated([Event]())

        try await withDependencies {
            $0.textRecognizer.recognize = { @Sendable configuration, scanningImage in
                events.withValue { $0.append(.recognize(configuration, scanningImage.base64EncodedString.count)) }
                return [.mock]
            }
            $0.validator.getValidatedResults = { @Sendable possibleLines in
                events.withValue { $0.append(.getValidatedResults(possibleLines)) }
                return [.mock]
            }
            $0.boundingRectConverter.convert = { @Sendable results, validLines in
                events.withValue { $0.append(.convert(results, validLines)) }
                return .mock
            }
            $0.parser.parse = { @Sendable mrzLines in
                events.withValue { $0.append(.parse(mrzLines)) }
                return .mock
            }

            $0.tracker.currentResults = { @Sendable in
                events.withValue { $0.append(.currentResults) }
                return .mock
            }
            $0.tracker.track = { @Sendable parserResult in
                events.withValue { $0.append(.track(parserResult)) }
            }
        } operation: {
            let resultsStream = AsyncStream<CIImage> { continuation in
                do {
                    continuation.yield(try XCTUnwrap(CIImage(data: .imageMock)))
                    continuation.finish()
                } catch {
                    let errorMessage = error.localizedDescription
                    XCTFail(errorMessage)
                    fatalError(errorMessage)
                }
            }
                .scanForMRZCode(configuration: .mock())

            for try await liveScanningResult in resultsStream {
                XCTAssertEqual(liveScanningResult.results, .mock)
                XCTAssertEqual(liveScanningResult.boundingRects, .mock)
                return
            }
        }

        XCTAssertNoDifference(
            events.value,
            [
                .recognize(.mock(), 1348268),
                .getValidatedResults([["test"]]),
                .parse(["test"]),
                .track(.mock),
                .currentResults,
                .convert([.mock], [.mock])
            ]
        )
    }

    func testImageStreamParsingFailure() async throws {
        let events = LockIsolated([Event]())

        try await withDependencies {
            $0.textRecognizer.recognize = { @Sendable configuration, scanningImage in
                events.withValue { $0.append(.recognize(configuration, scanningImage.base64EncodedString.count)) }
                return [.mock]
            }
            $0.validator.getValidatedResults = { @Sendable possibleLines in
                events.withValue { $0.append(.getValidatedResults(possibleLines)) }
                return [.mock]
            }
            $0.boundingRectConverter.convert = { @Sendable results, validLines in
                events.withValue { $0.append(.convert(results, validLines)) }
                return .mock
            }
            $0.parser.parse = { @Sendable mrzLines in
                events.withValue { $0.append(.parse(mrzLines)) }
                return nil
            }
            $0.tracker.currentResults = { @Sendable in
                events.withValue { $0.append(.currentResults) }
                return .mock
            }
        } operation: {
            let resultsStream = AsyncStream<CIImage> { continuation in
                do {
                    continuation.yield(try XCTUnwrap(CIImage(data: .imageMock)))
                    continuation.finish()
                } catch {
                    let errorMessage = error.localizedDescription
                    XCTFail(errorMessage)
                    fatalError(errorMessage)
                }
            }
                .scanForMRZCode(configuration: .mock())

            for try await liveScanningResult in resultsStream {
                XCTAssertEqual(liveScanningResult.results, .mock)
                XCTAssertEqual(liveScanningResult.boundingRects, .mock)
                return
            }
        }

        XCTAssertNoDifference(
            events.value,
            [
                .recognize(.mock(), 1348268),
                .getValidatedResults([["test"]]),
                .parse(["test"]),
                .currentResults,
                .convert([.mock], [.mock])
            ]
        )
    }

    func testImageStreamTextRecognizerFailure() async throws {
        let events = LockIsolated([Event]())

        try await withDependencies {
            $0.textRecognizer.recognize = { @Sendable configuration, scanningImage in
                events.withValue { $0.append(.recognize(configuration, scanningImage.base64EncodedString.count)) }
                throw CIImage.ScanningError.codeNotFound
            }
        } operation: {
            let resultsStream = AsyncStream<CIImage> { continuation in
                do {
                    continuation.yield(try XCTUnwrap(CIImage(data: .imageMock)))
                    continuation.finish()
                } catch {
                    let errorMessage = error.localizedDescription
                    XCTFail(errorMessage)
                    fatalError(errorMessage)
                }
            }
                .scanForMRZCode(configuration: .mock())

            do {
                for try await _ in resultsStream {
                    XCTFail("Should fail here")
                }
            } catch {
                let error = try XCTUnwrap(error as? CIImage.ScanningError)
                XCTAssertEqual(error, .codeNotFound)
            }
        }

        XCTAssertNoDifference(
            events.value,
            [
                .recognize(.mock(), 1348268)
            ]
        )
    }
}

private extension TextRecognizer.Result {
    static var mock: Self { .init(results: ["test"], boundingRect: .zero) }
}

private extension Validator.Result {
    static var mock: Self { .init(result: "test", index: 0) }
}

private extension TrackerResult {
    static var mock: Self { [.mock: 1] }
}

private extension Data {
    static var imageMock: Data {
        do {
            let fileURL = try XCTUnwrap(Bundle.module.url(forResource: "TestImage", withExtension: "png"))
            return try Data(contentsOf: fileURL)
        } catch {
            let errorMessage = error.localizedDescription
            XCTFail(errorMessage)
            fatalError(errorMessage)
        }
    }
}

private extension CIImage {
    var base64EncodedString: String {
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(self, from: self.extent) else {
            let errorMessage = "Failed to create CGImage"
            XCTFail(errorMessage)
            fatalError(errorMessage)
        }

        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        var data = Data(count: height * bytesPerRow)

        data.withUnsafeMutableBytes { ptr in
            if let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) {
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            }
        }

        return data.base64EncodedString()
    }
}

extension ScanningConfiguration: @retroactive Equatable {
    public static func == (lhs: ScanningConfiguration, rhs: ScanningConfiguration) -> Bool {
        lhs.orientation == rhs.orientation &&
        lhs.regionOfInterest == rhs.regionOfInterest &&
        lhs.minimumTextHeight == rhs.minimumTextHeight &&
        lhs.recognitionLevel == rhs.recognitionLevel
    }
}
