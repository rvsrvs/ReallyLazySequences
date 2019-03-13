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
        
        let c = SimpleSequence<Int>()
            .filter { $0 < 10 }
            .map { Double($0) }
            .map { $0 * 2 }
            .reduce([Double]()) {  $0 + [$1] }
            .map { return $0.sorted() }
            .flatMap { (input) -> Subsequence<[Double], Double> in Subsequence(input) }
            .map { (value: Double) -> Int in Int(value) }
            .reduce(0, +)
            .flatMap { (input) -> Subsequence<Int, Int> in Subsequence(0 ..< 3) { $0 * input } }
            .consume {
                if let value = $0 { accumulatedResults.append(value) }
                return .canContinue
            }
        
        XCTAssertNotNil(c as Consumer<Int>, "Consumer c is wrong type!")
        
        do {
            for i in [8, 12, 4, 3, 2] { _ = try c.process(i) }
            for _ in 0 ..< 100000 { _ = try c.process(200) }
            _ = try c.process(nil)
        } catch ReallyLazySequenceError.isComplete {
            print("Can't push to a completed sequence")
        } catch {
            print(error.localizedDescription)
        }
        
        XCTAssertEqual(accumulatedResults, [0,34,68])
    }
    
    func testSimpleListener() {
        let expectation = self.expectation(description: "First Listener")
        
        let listenable = ListenableSequence<Int>()
        
        var listernHandle = listenable
            .listener()
            .flatMap { (value) -> Subsequence<Int,Int> in Subsequence(0 ..< value) }
            .listen {
                guard $0 != nil else {
                    expectation.fulfill()
                    return .canContinue
                }
                return .canContinue 
            }
        
        do {
            try listenable.process(3)
            try listenable.process(nil)
        } catch {
            XCTFail("Failed while processing")
        }
        
        waitForExpectations(timeout: 1.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
        _ = listernHandle.terminate()
    }
    
    func testDispatch() {
        let expectation = self.expectation(description: "Complete RLS processing")
        let opQueue = OperationQueue()
        
        let c = SimpleSequence<Int>()
            .filter { $0 < 10 }
            .dispatch(opQueue)
            .map { (value: Int) -> Double in
                XCTAssertNotEqual(OperationQueue.current, OperationQueue.main)
                return Double(value)
            }
            .dispatch(OperationQueue.main)
            .consume {
                XCTAssertEqual(OperationQueue.current, OperationQueue.main)
                guard let value = $0 else { return .canContinue}
                XCTAssertNotEqual(value, 11.0)
                if value == 3.0 { expectation.fulfill() }
                return .canContinue
            }
        
        XCTAssertNotNil(c as Consumer<Int>, "Wrong class")
        
        do {
            try [1, 11, 2, 3, nil].forEach { _ = try c.process($0) }
        } catch ReallyLazySequenceError.isComplete {
            XCTFail("Can't push to a completed sequence")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        waitForExpectations(timeout: 10.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }
    
    func testCollect() {
        let expectation = self.expectation(description: "Complete RLS processing")
        let c = SimpleSequence<Int>()
            .collect(
                initialValue: [Int](),
                combine: { (partialValue, input) in return partialValue + [input] },
                until: { (partialValue, input) -> Bool in partialValue.count > 4 }
            )
            .flatMap { (collected: [Int]) -> Subsequence<[Int],Int> in
                var iterator = collected.makeIterator()
                return Subsequence { () -> Int? in iterator.next() }
            }
            .consume {
                guard $0 != nil else {
                    expectation.fulfill()
                    return .canContinue
                }
                return .canContinue
            }
        
        XCTAssertNotNil(c as Consumer<Int>, "Wrong class")
        
        do {
            try [1, 2, 3, 4, 5, 10, 20, 30, 40, 50, nil].forEach { _ = try c.process($0) }
        } catch ReallyLazySequenceError.isComplete {
            XCTFail("Can't push to a completed sequence")
        } catch {
            XCTFail(error.localizedDescription)
        }
        waitForExpectations(timeout: 10.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }
}
