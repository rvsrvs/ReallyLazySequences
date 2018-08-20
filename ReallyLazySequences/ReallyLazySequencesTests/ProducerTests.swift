//
//  ProducerTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 8/7/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import XCTest
@testable import ReallyLazySequences

class ProducerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testListenableProducer() {
        let doubler = self.expectation(description: "Doubler")
        let quadrupler = self.expectation(description: "Quadrupler")
        
        let testGenerator = ListenableGenerator<Int> { deliver in
            (0 ... 5).forEach { deliver($0) }
            deliver(nil)
        }
        
        testGenerator
            .listener()
            .map {  $0 * 2 }
            .listen {
                guard $0 == 10 else { return }
                doubler.fulfill()
            }
        
        testGenerator
            .listener()
            .map {  $0 * 4 }
            .listen {
                guard $0 == 20 else { return }
                quadrupler.fulfill()
            }
        
        try? testGenerator.generate()
        waitForExpectations(timeout: 30.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }
}
