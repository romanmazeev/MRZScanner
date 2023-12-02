//
//  Parser.swift
//
//
//  Created by Roman Mazeev on 02/12/2023.
//

import Dependencies
import MRZParser

struct Parser: Sendable {
    let parse: @Sendable (_ mrzLines: [String]) -> ParserResult?
}

extension Parser: DependencyKey {
    static var liveValue: Self {
        .init(
            parse: { mrzLines in
                MRZParser(isOCRCorrectionEnabled: true).parse(mrzLines: mrzLines)
            }
        )
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
    static var testValue: Self {
        Self(
            parse: unimplemented("Parser.parse")
        )
    }
}
#endif
