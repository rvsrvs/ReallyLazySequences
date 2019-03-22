//
//  ZipTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 8/24/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

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
        
        let listenable = ListenableSequence<Int>()
        
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
