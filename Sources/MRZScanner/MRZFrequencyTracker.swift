//
//  MRZFrequencyTracker.swift
//  
//
//  Created by Roman Mazeev on 13.07.2021.
//

import MRZParser

final class MRZFrequencyTracker {
    private let frequency: Int
    private var seenResults: [MRZResult: Int] = [:]

    init(frequency: Int) {
        self.frequency = frequency
    }

    func isResultStable(_ result: MRZResult) -> Bool {
        guard let seenResultFrequency = seenResults[result] else {
            seenResults[result] = 1
            return false
        }

        guard seenResultFrequency + 1 < frequency else {
            seenResults = [:]
            return true
        }

        seenResults[result]? += 1
        return false
    }
}
