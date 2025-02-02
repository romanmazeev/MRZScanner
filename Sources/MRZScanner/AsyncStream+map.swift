//
//  AsyncStream+map.swift
//  
//
//  Created by Roman Mazeev on 29/12/2022.
//

extension AsyncStream {
    public func map<Transformed>(_ transform: @escaping (Self.Element) async throws -> Transformed) -> AsyncThrowingStream<Transformed, Error> {
        return AsyncThrowingStream<Transformed, Error> { continuation in
            Task {
                for await element in self {
                    do {
                        continuation.yield(try await transform(element))
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                continuation.finish()
            }
        }
    }
}
