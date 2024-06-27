//
//  Validator.swift
//
//
//  Created by Roman Mazeev on 13.07.2021.
//

import Dependencies
import DependenciesMacros
import MRZParser

@DependencyClient
struct Validator: Sendable {
    struct Result {
        /// MRZLine
        let result: String
        /// MRZLine boundingRect index
        let index: Int
    }

    var getValidatedResults: @Sendable (_ possibleLines: [[String]]) -> [Result] = { _ in [] }
}

extension Validator: DependencyKey {
    static var liveValue: Self {
        .init { possibleLines in
            var validLines: [Result] = []

            for validMRZCode in MRZFormat.allCases {
                guard validLines.count < validMRZCode.linesCount else { break }
                for (index, lines) in possibleLines.enumerated() {
                    guard validLines.count < validMRZCode.linesCount else { break }
                    let spaceFreeLines = lines.lazy.map { $0.filter { !$0.isWhitespace } }
                    guard let mostLikelyLine = spaceFreeLines.first(where: {
                        $0.count == validMRZCode.lineLength
                    }) else { continue }
                    validLines.append(.init(result: mostLikelyLine, index: index))
                }

                if validLines.count != validMRZCode.linesCount {
                    validLines = []
                }
            }
            return validLines
        }
    }
}

extension DependencyValues {
    var validator: Validator {
        get { self[Validator.self] }
        set { self[Validator.self] = newValue }
    }
}

#if DEBUG
extension Validator: TestDependencyKey {
    static let testValue = Self()
}
#endif
