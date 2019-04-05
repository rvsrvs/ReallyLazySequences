//
//  CombineTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 4/5/19.
//

import XCTest
@testable import ReallyLazySequences

class CombineTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCombine2() {
        let expectation = self.expectation(description: "Expectation")
        
        let observable = Observable<Int>()
        
        let t0 = observable
            .observer
            .flatMap { (value) -> Subsequence<Int,Int> in
                var iterator = (0 ..< value).makeIterator()
                return Subsequence { iterator.next() }
            }
            .map {  $0 * 2 }
        
        let t1 = observable
            .observer
            .flatMap { (value) -> Subsequence<Int,Int> in
                var iterator = (0 ..< value).makeIterator()
                return Subsequence { iterator.next() }
            }
            .map { Double($0 * 4) }
            .map { $0 }
        
        var count = 0
        let c = combine(t0, t1, initialValue: (0,0))
            .observer
            .map { ($0.0 / 2, $0.1 / 2.0) }
            .observe { (t: (Int, Double)?) -> ContinuationTermination in
                guard let t = t else {
                    expectation.fulfill()
                    XCTAssert(count == 10 , "Terminating after having received wrong count of: \(count) values")
                    return .terminate
                }
                print("\(t)")
                count += 1
                return .canContinue
        }
        print(c.description)
        do {
            try observable.process(5)
            try observable.process(nil)
        } catch {
            XCTFail("Failed testZip processing")
        }
        
        waitForExpectations(timeout: 2.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }


    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
