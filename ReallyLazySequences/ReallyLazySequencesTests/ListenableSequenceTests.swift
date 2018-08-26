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
    
    func testListenableSequence() {
        let doubler = self.expectation(description: "Doubler")
        let quadrupler = self.expectation(description: "Quadrupler")
        
        let testGenerator = ListenableSequence<Int, Int> { (value: Int, delivery: @escaping (Int?) -> Void) -> Void in
            (0 ... value).forEach { delivery($0) }
            delivery(nil)
        }
        
        var proxy1 = testGenerator
            .listener()
            .map {  $0 * 2 }
            .listen {
                guard $0 == 10 else { return .canContinue }
                doubler.fulfill()
                return .canContinue
            }
        
        var proxy2 = testGenerator
            .listener()
            .map {  $0 * 4 }
            .listen {
                guard $0 == 20 else { return .canContinue }
                quadrupler.fulfill()
                return .canContinue
            }
        
        testGenerator.generate(for: 5)
        
        waitForExpectations(timeout: 30.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
        _ = proxy1.terminate()
        _ = proxy2.terminate()
    }
}
