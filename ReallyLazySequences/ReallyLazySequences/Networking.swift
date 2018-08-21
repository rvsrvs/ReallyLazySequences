//
//  Networking.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/8/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public typealias DataFetchValue = (data: Data?, response: URLResponse?, netError: Error?)

fileprivate let URLDataMapper = SimpleSequence<DataFetchValue>()
    .map { (result: DataFetchValue) -> Result<Data> in
        guard let response = result.response as? HTTPURLResponse, result.netError == nil else {
            return .failure(result.netError!)
        }
        guard response.statusCode >= 200 && response.statusCode < 300 else {
            let error = NSError(domain: "ReallyLazySequences.URLDataFetcher",
                                code: 1000,
                                userInfo: ["url" : response.url ?? "unknown", "response": response, "msg": "Invalid response"]
            )
            return .failure(error)
        }
        guard let data = result.data  else {
            let error = NSError(domain: "ReallyLazySequences.URLDataFetcher",
                                code: 1001,
                                userInfo: ["url" : response.url ?? "unknown", "response": response, "msg": "Valid response but no data"]
            )
            return .failure(error)
        }
        return .success(data)
    }

public struct URLDataFetcher: SubsequenceProtocol {
    public typealias InputType = (url: URL, session: URLSession)
    public typealias OutputType = Result<Data>
    public var generator: (InputType, @escaping (OutputType?) -> Void) -> Void
    
    public init(_ generator: @escaping ((url: URL, session: URLSession), @escaping (Result<Data>?) -> Void) -> Void) {
        self.generator = generator
    }
    
    public init() {
        self.init { (fetch: InputType, delivery: @escaping ((OutputType?) -> Void)) -> Void in
            let task = fetch.session.dataTask(with: fetch.url) {
                let c = URLDataMapper.consume{ result in
                    let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in
                        delivery(value)
                        return .done
                    }
                    _ = ContinuationResult.complete(
                        .afterThen(.more({ deliveryWrapper(result) }),
                               .more({ deliveryWrapper(nil) }))
                    )
                }
                _ = try? c.process(($0, $1, $2))
            }
            task.resume()
            while task.state != .completed { RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1)) }
        }
    }
}

public final class URLDataGenerator: ListenableGeneratorProtocol {
    public typealias InputType = (URL, URLSession)
    public typealias ListenableType = DataFetchValue
    public typealias ListenableSequenceType = ListenableSequence<DataFetchValue, URLDataGenerator>
    public var listeners = [UUID: Listener<DataFetchValue, URLDataGenerator>]()
    public var generator: (InputType, @escaping (ListenableType?) -> Void) -> Void

    public init(_ generator: @escaping (InputType, @escaping (ListenableType?) -> Void) -> Void) {
        self.generator = generator
    }

    convenience init() {
        self.init { (params: (URL, URLSession), delivery: @escaping ((DataFetchValue?) -> Void)) -> Void in
            params.1.dataTask(with: params.0) { delivery(($0, $1, $2)); delivery(nil) } .resume()
        }
    }
}

extension URLDataGenerator {
    public typealias DataListener = ListenableMap<ListenableSequence<DataFetchValue, URLDataGenerator>, Result<Data>>
    public func dataListener() -> DataListener {
        return listener()
            .map { (result: DataFetchValue) -> Result<Data> in
                guard let response = result.response as? HTTPURLResponse, result.netError == nil else {
                    return .failure(result.netError!)
                }
                guard response.statusCode >= 200 && response.statusCode < 300 else {
                    let error = NSError(domain: "ReallyLazySequences.URLDataProducer",
                                        code: 1000,
                                        userInfo: ["response": response, "msg": "Invalid response"]
                    )
                    return .failure(error)
                }
                guard let data = result.data  else {
                    let error = NSError(domain: "ReallyLazySequences.URLDataProducer",
                                        code: 1001,
                                        userInfo: ["response": response, "msg": "Valid response but no data"]
                    )
                    return .failure(error)
                }
                return .success(data)
            }
    }
    
    public func jsonListener<JSONType: Decodable>(decodingType: JSONType.Type) -> ListenableMap<DataListener, Result<JSONType>> {
        return dataListener()
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
