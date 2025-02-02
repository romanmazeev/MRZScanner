//
//  StubModels.swift
//  
//
//  Created by Roman Mazeev on 14.07.2021.
//

@testable import MRZScanner
import MRZParser
import CoreImage

struct StubModels {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
        return formatter
    }()

    static let firstParsedResult = MRZResult(
        format: .td3,
        documentType: .passport,
        documentTypeAdditional: nil,
        countryCode: "UTO",
        surnames: "ERIKSSON",
        givenNames: "ANNA MARIA",
        documentNumber: "L898902C3",
        nationalityCountryCode: "UTO",
        birthdate:  dateFormatter.date(from: "740812")!,
        sex: .female,
        expiryDate: dateFormatter.date(from: "120415")!,
        optionalData: "ZE184226B",
        optionalData2: nil
    )

    static let secondParsedResult = MRZResult(
        format: .td2,
        documentType: .id,
        documentTypeAdditional: "A",
        countryCode: "",
        surnames: "",
        givenNames: "",
        documentNumber: nil,
        nationalityCountryCode: "",
        birthdate: nil,
        sex: .male,
        expiryDate: nil,
        optionalData: nil,
        optionalData2: nil
    )
}
