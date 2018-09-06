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
            .flatMap { (input: [Double]) -> Subsequence<[Double], Double> in
                var current: [Double] = input
                return Subsequence<[Double], Double> { () -> Double? in
                    guard let value = current.first else { return nil }
                    current = Array(current.dropFirst())
                    return value
                }
            }
            .map { (value: Double) -> Int in Int(value) }
            .reduce(0, +)
            .flatMap { (input: Int) -> Subsequence<Int, Int> in
                var current = Array<Int>(0 ..< 3)
                return Subsequence<Int, Int> { () -> Int? in
                    guard let value = current.first else { return nil }
                    current = Array(current.dropFirst())
                    return value * input
                }
            }
            .consume { if let value = $0 { accumulatedResults.append(value) }; return .canContinue }
        
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
        
        let listenable = ListenableSequence<Int, Int> { (value: Int, delivery: @escaping (Int?) -> Void) -> Void in
            (0 ..< value).forEach { delivery($0) }
            delivery(nil)
        }
        
        var listernHandle = listenable
            .listener()
            .listen {
                guard $0 != nil else {
                    expectation.fulfill()
                    return .canContinue
                }
                return .canContinue 
            }
        
        listenable.generate(for: 3)
        
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
                var current: [Int] = collected
                return Subsequence { () -> Int? in
                    guard let value = current.first else { return nil }
                    current = Array(current.dropFirst())
                    return value
                }
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
