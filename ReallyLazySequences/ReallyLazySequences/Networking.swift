//
//  Networking.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/8/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public typealias DataFetchValue = (data: Data?, response: URLResponse?, netError: Error?)

public struct URLDataFetcher: ReallyLazySequenceProtocol {
    public typealias InputType = (url: URL, session: URLSession)
    public typealias OutputType = Result<Data>
    public var generator: (InputType, @escaping (OutputType?) -> Void) -> Void
    
    private typealias Composition = () -> Void
    private var composition: Composition?
    
    public init() {
        self.generator = { (fetch: InputType, delivery: @escaping ((Result<Data>?) -> Void)) -> Void in
            let task = fetch.session.dataTask(with: fetch.url) {
                let c = ReallyLazySequence<DataFetchValue>()
                    .map { (result: DataFetchValue) -> Result<Data> in
                        guard let response = result.response as? HTTPURLResponse, result.netError == nil else {
                            return .failure(result.netError!)
                        }
                        guard response.statusCode >= 200 && response.statusCode < 300 else {
                            let error = NSError(domain: "ReallyLazySequences.URLDataFetcher",
                                                code: 1000,
                                                userInfo: ["url" : fetch.url, "response": response, "msg": "Invalid response"]
                            )
                            return .failure(error)
                        }
                        guard let data = result.data  else {
                            let error = NSError(domain: "ReallyLazySequences.URLDataFetcher",
                                                code: 1001,
                                                userInfo: ["url" : fetch.url, "response": response, "msg": "Valid response but no data"]
                            )
                            return .failure(error)
                        }
                        return .success(data)
                    }
                    .consume{ result in
                        delivery(result)
                        delivery(nil)
                    }
                try? c.process(($0, $1, $2))
            }
            task.resume()
            while task.state != .completed { RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1)) }
        }
    }
    
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> InputDelivery {
        let deliveryWrapper = { (output: OutputType?) -> Void in drive(delivery(output)) }
        return { (input: InputType?) throws -> Void in
            guard let input = input else { deliveryWrapper(nil); return }
            self.generator(input, deliveryWrapper)
        }
    }
}

public class URLDataProducer: ProducerProtocol {
    public typealias ListenableType = DataFetchValue
    public typealias ListenableSequenceType = ListenableSequence<DataFetchValue>
    public var listeners = [UUID: Listener<DataFetchValue>]()
    public var producer: (@escaping (DataFetchValue?) -> Void) -> Void

    var url: URL!
    
    public required init(producer: @escaping ((DataFetchValue?) -> Void) -> Void) {
        self.producer = producer
    }

    convenience init(url: URL, session: URLSession) {
        self.init { (_) in }
        self.url = url
        self.producer = { (delivery: @escaping ((DataFetchValue?) -> Void)) -> Void in
            session.dataTask(with: url) { delivery(($0, $1, $2)); delivery(nil) } .resume()
        }
    }
}

extension URLDataProducer {
    public typealias DataListener = Map<ListenableSequence<DataFetchValue>, Result<Data>>
    public func dataListener() -> DataListener {
        return listener()
            .map { (result: DataFetchValue) -> Result<Data> in
                guard let response = result.response as? HTTPURLResponse, result.netError == nil else {
                    return .failure(result.netError!)
                }
                guard response.statusCode >= 200 && response.statusCode < 300 else {
                    let error = NSError(domain: "ReallyLazySequences.URLDataProducer",
                                        code: 1000,
                                        userInfo: ["url" : self.url, "response": response, "msg": "Invalid response"]
                    )
                    return .failure(error)
                }
                guard let data = result.data  else {
                    let error = NSError(domain: "ReallyLazySequences.URLDataProducer",
                                        code: 1001,
                                        userInfo: ["url" : self.url, "response": response, "msg": "Valid response but no data"]
                    )
                    return .failure(error)
                }
                return .success(data)
            }
    }
    
    public func jsonListener<JSONType: Decodable>(decodingType: JSONType.Type) -> Map<DataListener, Result<JSONType>> {
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
                                                        "url" : self.url,
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
