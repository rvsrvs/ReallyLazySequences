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
            .flatMap { (input: [Double]) -> GeneratingSequence<[Double], Double> in
                GeneratingSequence { (_: [Double], delivery: (Double?) -> Void) in
                    input.forEach { delivery($0) }
                }
            }
            .map { (value: Double) -> Int in Int(value) }
            .reduce(0, +)
            .flatMap { (input: Int) -> GeneratingSequence<Int, Int> in
                GeneratingSequence { (_: Int, delivery: (Int?) -> Void)  in
                    (0 ..< 3).forEach { delivery($0 * input) }
                }
            }
            .consume { if let value = $0 { accumulatedResults.append(value) } }
        
        XCTAssertNotNil(c as Consumer<ConsumableFlatMap<ConsumableReduce<ConsumableMap<ConsumableFlatMap<ConsumableMap<ConsumableReduce<ConsumableMap<ConsumableMap<ConsumableFilter<SimpleSequence<Int>, Int>, Double>, Double>, Array<Double>>, Array<Double>>, Double>, Int>, Int>, Int>>,
                    "Consumer c is wrong type!")
        
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
    
    func testSimpleProducer() {
        let firstExpectation = self.expectation(description: "First Listener")
        
        let generator = ListenableGenerator<Int> { deliver in
            (0 ..< 3).forEach { deliver($0) }
            deliver(nil)
        }
        
        var proxy = generator
            .listener()
            .listen {  guard $0 != nil else { firstExpectation.fulfill(); return } }
        
        do {
            try generator.generate()
        } catch {
            XCTFail(error.localizedDescription)
        }
        waitForExpectations(timeout: 40.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
        proxy.terminate()
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
                guard let value = $0 else { return }
                XCTAssertNotEqual(value, 11.0)
                if value == 3.0 { expectation.fulfill() }
            }
        
        XCTAssertNotNil(c as Consumer<ConsumableDispatch<ConsumableMap<ConsumableDispatch<ConsumableFilter<SimpleSequence<Int>, Int>, Int>, Double>, Double>>,
                        "Wrong class")
        
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
                combine: { (partialValue, input) -> [Int] in return partialValue + [input] },
                until: { (partialValue, input) -> Bool in partialValue.count > 4 }
            )
            .flatMap { (collected: [Int]) in
                GeneratingSequence<[Int],Int> { (input, delivery) in
                    input.forEach { delivery($0) }
                }
            }
            .consume {
                guard $0 != nil else {
                    expectation.fulfill()
                    return
                }
            }
        
        XCTAssertNotNil(c as Consumer<ConsumableFlatMap<ConsumableReduce<SimpleSequence<Int>, Array<Int>>, Int>>, "Wrong class")
        
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
