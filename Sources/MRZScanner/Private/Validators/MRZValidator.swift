//
//  MRZValidator.swift
//  
//
//  Created by Roman Mazeev on 13.07.2021.
//

import MRZParser

struct MRZValidator: Validator {
    func getValidatedResults(from possibleLines: [[String]]) -> ValidatedResults {
        var validLines = ValidatedResults()

        for validMRZCode in MRZFormat.allCases {
            guard validLines.count < validMRZCode.linesCount else { break }
            for (index, lines) in possibleLines.enumerated() {
                guard validLines.count < validMRZCode.linesCount else { break }
                guard let mostLikelyLine = lines.first(where: {
                    $0.count == validMRZCode.lineLenth
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