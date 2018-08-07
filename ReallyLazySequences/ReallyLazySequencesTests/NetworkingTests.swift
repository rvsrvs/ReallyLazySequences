//
//  RLSNetworkingTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import XCTest
@testable import ReallyLazySequences

class NetworkingTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNetworkProcessing() {
        let expectation = self.expectation(description: "Complete RLS processing")
        guard let url = URL(string: ConfigurationURL) else { return }
        let session = FetcherSupport().session()
        
        let task = DataFetcher(session: session, url: url)
            .listener
            .map { (result: DataFetchValue) -> Result<Data> in
                guard let response = result.response as? HTTPURLResponse, result.netError == nil else {
                    return .failure(result.netError!.localizedDescription)
                }
                guard response.statusCode >= 200 && response.statusCode < 300 else {
                    return .failure("Invalid response: \(response.description)")
                }
                guard let data = result.data  else {
                    return .failure("Valid response but no data")
                }
                return .success(data)
            }
            .map { (fetchResult: Result<Data>) -> Result<[Configuration]> in
                switch fetchResult {
                case .success(let data):
                    do {
                        let configuration = try JSONDecoder().decode([Configuration].self, from: data)
                        return .success(configuration)
                    } catch {
                        return .failure(error.localizedDescription)
                    }
                case .failure(let message):
                    return .failure(message)
                }
            }
            .consume {
                guard let result = $0 else {
                    print("End of Sequence")
                    expectation.fulfill()
                    return
                }
                switch result {
                case .success(let config):
                    print(config)
                case .failure(let message):
                    print(message)
                }
            }
        
        do {
            try task.push(nil)
        } catch {
            print(error)
        }
        
        waitForExpectations(timeout: 40.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }
}

enum Result<T> {
    case success(T)
    case failure(String)
    
    var successful: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
}

typealias DataFetchValue = (data: Data?, response: URLResponse?, netError: Error?)

struct DataFetcher {
    var session: URLSession
    var url: URL
    
    var listener:  Producer<DataFetchValue> {
        return Producer<DataFetchValue> { delivery in
            self.session.dataTask(with: self.url) { (data: Data?, response: URLResponse?, netError: Error?) in
                let response = (data: data, response: response, netError: netError)
                delivery(response)
                delivery(nil)
            }
            .resume()
        }
    }
}

//=============================
//       Test Support
//=============================
struct Configuration : Encodable, Decodable {
    private enum CodingKeys : String, CodingKey {
        case title = "title"
        case contents = "contents"
    }
    let title : String?
    let contents: [[Int]]?
}

fileprivate let WeatherURL = "https://api.openweathermap.org/data/2.5/weather?q=Boston&appid=77e555f36584bc0c3d55e1e584960580"
fileprivate let ConfigurationURL = "https://www.dropbox.com/s/i4gp5ih4tfq3bve/S65g.json?dl=1"

class FetcherSupport: NSObject, URLSessionDelegate {
    func session() -> URLSession {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration,
                          delegate: self,
                          delegateQueue: nil)
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        NSLog("\(#function): Session received authentication challenge")
        completionHandler(.performDefaultHandling,nil)
    }
}

