//
//  Networking.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/8/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
    
    var successful: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
}

public class URLDataProducer: ProducerProtocol {
    public typealias DataFetchValue = (data: Data?, response: URLResponse?, netError: Error?)
    public typealias ListenableType = DataFetchValue
    public typealias ListenableSequenceType = ListenableSequence<DataFetchValue>
    public var listeners = [UUID: Listener<DataFetchValue>]()
    public var producer: (@escaping (URLDataProducer.DataFetchValue?) -> Void) -> Void

    var url: URL!
    
    public required init(producer: @escaping ((URLDataProducer.DataFetchValue?) -> Void) -> Void) {
        self.producer = producer
    }

    convenience init(url: URL, session: URLSession) {
        self.init { (_) in }
        self.url = url
        self.producer = { (delivery: @escaping ((URLDataProducer.DataFetchValue?) -> Void)) -> Void in
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
