//
//  MRZValidator.swift
//  
//
//  Created by Roman Mazeev on 13.07.2021.
//

import MRZParser

struct MRZValidator {
    struct Result {
        /// MRZLine
        let result: String
        /// MRZLine boundingRect index
        let index: Int
    }

    static func getValidatedResults(from possibleLines: [[String]]) -> [Result] {
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

    private init() {}
}
