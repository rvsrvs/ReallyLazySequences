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
        let firstExpectation = self.expectation(description: "First Listener")
        let secondExpectation = self.expectation(description: "Second Listener")

        guard let url = URL(string: ConfigurationURL) else { return }
        
        let producer = URLDataProducer(url: url, session: SessionSupport().session())
        
        producer
            .jsonListener(decodingType: [Configuration].self)
            .dispatch(OperationQueue.main)
            .listen {
                guard let result = $0 else { return }
                switch result {
                case .success:
                    firstExpectation.fulfill()
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
        
        producer
            .jsonListener(decodingType: [Configuration].self)
            .listen {
                guard let result = $0 else { return }
                switch result {
                case .success:
                    secondExpectation.fulfill()
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
        }

        do {
            try producer.produce()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        waitForExpectations(timeout: 40.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
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

class SessionSupport: NSObject, URLSessionDelegate {
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

