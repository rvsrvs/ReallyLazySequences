//
//  ReallyLazySequencesTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 5/6/17.
//

/*
 Copyright 2019, Ronald V. Simmons
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import XCTest
@testable import ReallyLazySequences

class SequenceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSimpleSequence() {
        var accumulatedResults: [Int] = []
        
        let c = SequenceHead<Int>()
            .filter { $0 < 10 }
            .map { Double($0) }
            .map { (input: Double) -> Double in input * 2 }
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
        } catch ConsumerError.isComplete {
            print("Can't push to a completed sequence")
        } catch {
            print(error.localizedDescription)
        }
        
        XCTAssertEqual(accumulatedResults, [0,34,68])
    }
    
    func testSimpleObserver() {
        let expectation = self.expectation(description: "First Observer")
        
        let observer = Observable<Int>()
        
        var observerHandle = observer
            .observer
            .flatMap { (value) -> Subsequence<Int,Int> in Subsequence(0 ..< value) }
            .observe {
                guard $0 != nil else {
                    expectation.fulfill()
                    return .canContinue
                }
                return .canContinue 
            }
        
        do {
            try observer.process(3)
            try observer.process(nil)
        } catch {
            XCTFail("Failed while processing")
        }
        
        waitForExpectations(timeout: 1.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
        _ = observerHandle.terminate()
    }
    
    func testDispatch() {
        let expectation = self.expectation(description: "Complete RLS processing")
        let opQueue = OperationQueue()
        
        let c = SequenceHead<Int>()
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
        } catch ConsumerError.isComplete {
            XCTFail("Can't push to a completed sequence")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        waitForExpectations(timeout: 10.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }
    
    func testCollect() {
        let expectation = self.expectation(description: "Complete RLS processing")
        let c = SequenceHead<Int>()
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
        } catch ConsumerError.isComplete {
            XCTFail("Can't push to a completed sequence")
        } catch {
            XCTFail(error.localizedDescription)
        }
        waitForExpectations(timeout: 10.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }
}
