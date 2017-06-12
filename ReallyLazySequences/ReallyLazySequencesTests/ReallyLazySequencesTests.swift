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
    
    func testSimpleSequence() {
        var accumulatedResults: [Int] = []
        
        let s = ReallyLazySequence<Int>()
            .filter { $0 < 10 }
            .map { Double($0) }
            .map {  $0 * 2 }
            .sort(<)
            .map { (value: Double) -> Int in Int(value) }
            .reduce(0) {(partialResult: Int, value: Int) -> Int in
                return (partialResult + value)
            }
            .flatMap { (value: Int) -> Producer<Int> in
                return Producer<Int> { (delivery: (_: Int?) -> Void) in
                    ( 0 ..< 3).forEach { delivery($0 * value) }
                }
            }
            .consume {
                if let value = $0 { accumulatedResults.append(value) }
                return { nil }
            }
        
        print(type(of:s))
        
        do {
            for _ in 0 ..< 100000 { try s.push(200) }
            for i in [8, 12, 4, 3, 2] { try s.push(i) }
            try s.push(nil)
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
}
