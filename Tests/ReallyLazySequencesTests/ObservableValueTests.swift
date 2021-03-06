//
//  ObserverTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 8/6/18.
//

/*
 Copyright 2019, Ronald V. Simmons
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import XCTest
@testable import ReallyLazySequences

class ObservableValueTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testObservableValue() {
        let doubler = self.expectation(description: "Doubler")
        let quadrupler = self.expectation(description: "Quadrupler")
        
        let observableValue = Value(2)
        
        var proxy1 = observableValue
            .observer
            .map { $0 * 2 }
            .observe {
                guard $0 != nil else { XCTFail(); return .canContinue  }
                doubler.fulfill()
                return .canContinue 
            }
        
        var proxy2 = observableValue
            .observer
            .map { $0 * 4 }
            .observe {
                guard $0 != nil else { XCTFail(); return .canContinue  }
                quadrupler.fulfill()
                return .canContinue
            }
        
        observableValue.value = 4
        waitForExpectations(timeout: 2.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
        _ = proxy1.terminate()
        _ = proxy2.terminate()
    }
}
