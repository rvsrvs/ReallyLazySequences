//
//  ZipTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 8/24/18.
//

/*
 Copyright 2019, Ronald V. Simmons
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import XCTest
@testable import ReallyLazySequences

class ZipTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testZip() {
        let expectation = self.expectation(description: "Expectation")
        
        let listenable = Observer<Int>()
        
        let t0 = listenable
            .listener
            .flatMap { (value) -> Subsequence<Int,Int> in
                var iterator = (0 ..< value).makeIterator()
                return Subsequence { iterator.next() }
            }
            .map {  $0 * 2 }
        
        let t1 = listenable
            .listener
            .flatMap { (value) -> Subsequence<Int,Int> in
                var iterator = (0 ..< value).makeIterator()
                return Subsequence { iterator.next() }
            }
            .map { Double($0 * 4) }
        
        var count = 0
        let z = zip(t0, t1)
            .listener
            .map { ($0.0 / 2, $0.1 / 2.0) }
            .listen { (t: (Int, Double)?) -> ContinuationTermination in
                guard let t = t else {
                    expectation.fulfill()
                    XCTAssert(count == 5, "Terminating after having received wrong count of: \(count) values")
                    return .terminate
                }
                XCTAssert(t.1 == Double(2 * t.0), "Terminating after incorrect computation")
                count += 1
                return .canContinue
            }
        print(z.description)
        do {
            try listenable.process(5)
            try listenable.process(nil)
        } catch {
            XCTFail("Failed testZip processing")
        }
        
        waitForExpectations(timeout: 2.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }
}
