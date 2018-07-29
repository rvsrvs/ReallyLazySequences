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
    
    func testSimpleSequence() {
        var accumulatedResults: [Int] = []
        
        let c = ReallyLazySequence<Int>()
            .filter { $0 < 10 }
            .map { Double($0) }
            .map { $0 * 2 }
            .sort(<)
            .map { (value: Double) -> Int in Int(value) }
            .reduce(0, +) 
            .flatMap { (value: Int) -> Producer<Int> in
                return Producer<Int> { (delivery: (_: Int?) -> Void) in
                    ( 0 ..< 3).forEach { delivery($0 * value) }
                }
            }
            .consume {
                if let value = $0 { accumulatedResults.append(value) }
                return { nil }
            }

        XCTAssertNotNil(c as Consumer<FlatMap<Reduce<Map<Sort<Map<Map<Filter<ReallyLazySequence<Int>, Int>, Double>, Double>, Double>, Int>, Int>, Int>>,
                        "Consumer c is wrong type!")
        
        do {
            for _ in 0 ..< 100000 { try c.push(200) }
            for i in [8, 12, 4, 3, 2] { try c.push(i) }
            try c.push(nil)
        } catch ReallyLazySequenceError.isComplete {
            print("Can't push to a completed sequence")
        } catch {
            print(error.localizedDescription)
        }
        
        XCTAssertEqual(accumulatedResults, [0,34,68])
    }
    
    func testSimpleProducer() {
        let producer = Producer<Int> { (delivery: (_: Int?) -> Void) in
            ( 0 ..< 3).forEach {
                delivery($0)
            }
        }
        let task = producer.consume { (value: Int?) -> Continuation in
            print(String(describing: value))
            return { nil }
        }
        do {
            try task.push(nil)
            try task.push(nil)
        } catch {
            print(error)
        }
    }
    
    func testDispatch() {
        let expectation = self.expectation(description: "Complete RLS processing")
        let opQueue = OperationQueue()
        
        let c = ReallyLazySequence<Int>()
            .filter { $0 < 10 }
            .dispatch(opQueue)
            .map { (value: Int) -> Double in
                XCTAssertNotEqual(OperationQueue.current, OperationQueue.main)
                return Double(value)
            }
            .dispatch(OperationQueue.main)
            .consume {
                XCTAssertEqual(OperationQueue.current, OperationQueue.main)
                guard let value = $0 else { return { nil } }
                XCTAssertNotEqual(value, 11.0)
                if value == 3.0 {
                    expectation.fulfill()
                }
                return { nil }
            }
        
        XCTAssertNotNil(c as Consumer<Dispatch<Map<Dispatch<Filter<ReallyLazySequence<Int>, Int>, Int>, Double>, Double>>,
                        "Wrong class")
        
        do {
            try c.push(1)
            try c.push(11)
            try c.push(2)
            try c.push(3)
            try c.push(nil)
        } catch ReallyLazySequenceError.isComplete {
            XCTFail("Can't push to a completed sequence")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        waitForExpectations(timeout: 10.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }
    
    func testCollect() {
        let c = ReallyLazySequence<Int>()
            .collect( initialValue: { [Int]() }, combine: { $0 + [$1] }, until: { $0.count > 4 } )
            .flatMap { (value: [Int]) -> Producer<Int> in
                return Producer<Int> { (delivery: (_: Int?) -> Void) in value.forEach { delivery($0) } }
            }
            .consume {
                if let value = $0 { print(value) }
                return { nil }
            }
        
        do {
            try c.push(1)
            try c.push(2)
            try c.push(3)
            try c.push(4)
            try c.push(5)
            try c.push(nil)
        } catch ReallyLazySequenceError.isComplete {
            XCTFail("Can't push to a completed sequence")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
