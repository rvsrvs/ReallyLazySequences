//
//  ListenerTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 8/6/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import XCTest
@testable import ReallyLazySequences

class ListenerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testListenableValue() {
        let doubler = self.expectation(description: "Doubler")
        let quadrupler = self.expectation(description: "Quadrupler")
        
        let testValue = ListenableValue<Int>(2)
        
        var proxy1 = testValue
            .listener()
            .map { $0 * 2 }
            .listen {
                guard $0 != nil else { XCTFail(); return .canContinue  }
                doubler.fulfill()
                return .canContinue 
            }
        
        var proxy2 = testValue
            .listener()
            .map { $0 * 4 }
            .listen {
                guard $0 != nil else { XCTFail(); return .canContinue  }
                quadrupler.fulfill()
                return .canContinue
            }
        
        testValue.value = 4
        waitForExpectations(timeout: 2.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
        _ = proxy1.terminate()
        _ = proxy2.terminate()
    }
}
