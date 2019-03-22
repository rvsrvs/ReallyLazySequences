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
        
        let testGenerator = Observer<Int>()
        
        var proxy1 = testGenerator
            .listener
            .flatMap { (value) -> Subsequence<Int,Int> in
                var iterator = (0 ..< value).makeIterator()
                return Subsequence { iterator.next() }
            }
            .map { $0 * 2 }
            .listen {
                guard let value = $0 else { doubler.fulfill(); return .terminate }
                guard value < 10 else { return .terminate }
                return .canContinue
            }
        
        var proxy2 = testGenerator
            .listener
            .flatMap { (value) -> Subsequence<Int,Int> in
                var iterator = (0 ..< value).makeIterator()
                return Subsequence { iterator.next() }
            }
            .map { $0 * 4 }
            .listen {
                guard let value = $0 else { quadrupler.fulfill(); return .terminate }
                guard value < 20 else { return .terminate }
                return .canContinue
            }
        
        do {
            try testGenerator.process(5)
            try testGenerator.process(nil)
        } catch {
            XCTFail("Failed while processing")
        }
        
        waitForExpectations(timeout: 5.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
        _ = proxy1.terminate()
        _ = proxy2.terminate()
    }
}
