//
//  Parser.swift
//
//
//  Created by Roman Mazeev on 02/12/2023.
//

import Dependencies
import DependenciesMacros
import MRZParser

public typealias ParserResult = MRZResult

@DependencyClient
struct Parser: Sendable {
    var parse: @Sendable (_ mrzLines: [String]) -> ParserResult?
}

extension Parser: DependencyKey {
    static var liveValue: Self {
        .init { mrzLines in
            MRZParser(isOCRCorrectionEnabled: true).parse(mrzLines: mrzLines)
        }
    }
}

extension DependencyValues {
    var parser: Parser {
        get { self[Parser.self] }
        set { self[Parser.self] = newValue }
    }
}

#if DEBUG
extension Parser: TestDependencyKey {
    static let testValue = Self()
}
#endif
