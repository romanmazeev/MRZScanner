[![Build and test](https://github.com/romanmazeev/MRZScanner/actions/workflows/Build%20and%20test.yml/badge.svg)](https://github.com/romanmazeev/MRZScanner/actions/workflows/Build%20and%20test.yml)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://github.com/romanmazeev/MRZScanner/blob/master/Package.swift)

# MRZScanner
Library for scanning documents via [MRZ](https://en.wikipedia.org/wiki/Machine-readable_passport) using [ Vision API](https://developer.apple.com/documentation/vision/vnrecognizetextrequest).

## Requirements
* iOS 13.0+
* macOS 10.15+
* Mac Catalyst 13.0+
* tvOS 13.0+

## Installation guide
### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/romanmazeev/MRZScanner.git", .upToNextMajor(from: "1.1.6"))
]
```
*The library has an SPM [dependency](https://github.com/romanmazeev/MRZParser) for MRZ code parsing.*

## Usage

1. For both image scanning and live scanning, we need to create `ScanningConfiguration`
```swift
ScanningConfiguration(orientation: .up, regionOfInterest: roi, minimumTextHeight: 0.1, recognitionLevel: .fast)
```

2. After you need to start scanning
```swift
/// Live scanning
for try await scanningResult in imageStream.scanForMRZCode(configuration: configuration) {
    // Handle `scanningResult` here
    
    // Use `return` to cancel scanning
    return
}

/// Single scanning
let scanningResult = try await image.scanForMRZCode(configuration: configuration)
```

## Example
![gif](./Docs/MRZScannerExample.gif)

The example project is located inside the [`Example` folder](https://github.com/romanmazeev/MRZScanner/tree/master/Example). 
*To run it, you need a device with the [minimum required OS version](https://github.com/romanmazeev/MRZScanner#requirements).*

## Credits

The project started as a fork of the [public repository](https://github.com/appintheair/MRZScanner) which I created when was working in [App In The Air](https://github.com/appintheair).

## License
The library is distributed under the [MIT LICENSE](https://opensource.org/licenses/MIT).
