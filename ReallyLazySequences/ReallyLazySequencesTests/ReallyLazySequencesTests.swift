//
//  ReallyLazySequencesTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 5/6/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

import XCTest
@testable import ReallyLazySequences

class ReallyLazySequencesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testQueueHandling() {
    }
    
    func testSimpleSynchronousSequence() {
        var accumulatedResults: [Int] = []
        let s = AsynchronousSequence<Int>()
            .filter { $0 < 10 }
            .map { Double($0) }
            .map { $0 * 2 }
            .sort(<)
            .map { (value: Double) -> Int in Int(value) }
            .reduce(0) {(partialResult: Int, value: Int) -> Int in return (partialResult + value) }
            .observe { if let value = $0 { accumulatedResults.append(value) } }
        
        print(type(of:s))
        
        do {
            try s.push(8)
            try s.push(12)
            try s.push(4)
            try s.push(3)
            try s.push(2)
            try s.push(nil)
        } catch AsynchronousSequenceError.isComplete {
            print("Can't push to a completed sequence")
        } catch {
            print(error.localizedDescription)
        }
        
//        XCTAssertEqual(accumulatedResults, [4, 6, 8, 16])
        XCTAssertEqual(accumulatedResults, [34])
    }
}
