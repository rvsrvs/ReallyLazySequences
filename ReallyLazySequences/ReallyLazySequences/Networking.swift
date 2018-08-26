//
//  Networking.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/8/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public typealias DataFetchValue = (data: Data?, response: URLResponse?, netError: Error?)

extension URLSession {
    func dataTask(with url: URL, completionHandler: @escaping (Result<Data>) -> Void) -> URLSessionTask {
        return dataTask(with: url) { (data: Data?, response: URLResponse?, netError: Error?) in
            guard let response = response as? HTTPURLResponse, netError == nil else {
                return completionHandler(.failure(netError!))
            }
            guard response.statusCode >= 200 && response.statusCode < 300 else {
                let error = NSError(domain: "ReallyLazySequences.URLDataFetcher",
                                    code: 1000,
                                    userInfo: ["url" : response.url ?? "unknown", "response": response, "msg": "Invalid response"]
                )
                return completionHandler(.failure(error))
            }
            guard let data = data  else {
                let error = NSError(domain: "ReallyLazySequences.URLDataFetcher",
                                    code: 1001,
                                    userInfo: ["url" : response.url ?? "unknown", "response": response, "msg": "Valid response but no data"]
                )
                return completionHandler(.failure(error))
            }
            completionHandler(.success(data))
        }
    }
}

public struct URLDataSubsequence: SubsequenceProtocol {
    public typealias InputType = (url: URL, session: URLSession)
    public typealias OutputType = Result<Data>
    public var description: String = "URLDataFetcher"
    public var generator: (InputType, @escaping (OutputType?) -> Void) -> Void
    
    public init(_ generator: @escaping ((url: URL, session: URLSession), @escaping (Result<Data>?) -> Void) -> Void) {
        self.generator = generator
    }
    
    public init() {
        self.init { (fetch: InputType, delivery: @escaping ((OutputType?) -> Void)) -> Void in
            let c = SimpleSequence<Result<Data>>()
                .consume { result in
                    let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in
                        delivery(value)
                        return .done(.canContinue)
                    }
                    _ = ContinuationResult.complete(
                        .afterThen(.more({ deliveryWrapper(result) }),
                                   .more({ deliveryWrapper(nil) }))
                    )
                    return .canContinue
                }
            
            let task = fetch.session.dataTask(with: fetch.url) { (result: Result<Data>) in _ = try? c.process(result) }
            task.resume()
            while task.state != .completed { RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1)) }
        }
    }
}

public final class URLDataGenerator: ListenableSequenceProtocol {
    public typealias InputType = (URL, URLSession)
    public typealias ListenableOutputType = Result<Data>
    public var listeners = [UUID: Consumer<Result<Data>>]()
    public var sequenceGenerator: (InputType, @escaping (ListenableOutputType?) -> Void) -> Void

    public init(_ generator: @escaping (InputType, @escaping (ListenableOutputType?) -> Void) -> Void) {
        self.sequenceGenerator = generator
    }

    convenience init() {
        self.init { (params: (URL, URLSession), delivery: @escaping ((Result<Data>?) -> Void)) -> Void in
            params.1.dataTask(with: params.0) { delivery($0); delivery(nil) } .resume()
        }
    }
}

extension URLDataGenerator {
    public func jsonListener<JSONType: Decodable>(
        decodingType: JSONType.Type
    ) -> ListenableMap<Listener<URLDataGenerator>, Result<JSONType>> {
        return listener()
            .map { (fetchResult: Result<Data>) -> Result<JSONType> in
                switch fetchResult {
                case .success(let data):
                    do {
                        let configuration = try JSONDecoder().decode(decodingType, from: data)
                        return .success(configuration)
                    } catch {
                        let wrappingError = NSError(domain: "ReallyLazySequences.URLDataProducer",
                                                    code: 1002,
                                                    userInfo: [
                                                        "json": data,
                                                        "msg": "Error decoding json as type: \(type(of: decodingType))",
                                                        "error": error
                                                    ]
                        )
                        return .failure(wrappingError)
                    }
                case .failure(let error):
                    return .failure(error)
                }
            }
    }
}
