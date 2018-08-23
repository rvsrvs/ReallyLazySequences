//
//  ContinuationTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 8/15/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import XCTest
@testable import ReallyLazySequences

class ContinuationTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    enum ReallyLazySequenceError: Error {
        case isComplete
        case nonPushable
        case noListeners
        
        var description: String {
            switch self {
            case .isComplete:
                return "ReallyLazySequence has already completed.  Pushes not allowed"
            case .nonPushable:
                return "push may only be called on Sequences which are NOT already attached to producers"
            case .noListeners:
                return "No listeners available for producer to produce into"
            }
        }
    }

    func testNonThrowingChaining() {
        let expectation = self.expectation(description: "Complete Path 0 processing")
        let expectation0 = self.expectation(description: "Complete Path 1 processing")
        let expectation1 = self.expectation(description: "Complete Path 2 processing")
        var fulfillCount = 0
        
        let continuation1 = {() -> ContinuationResult in
            XCTAssertTrue(fulfillCount == 0, "Messages in wrong order at continuation 1")
            fulfillCount += 1
            expectation.fulfill()
            return ContinuationResult.done(.canContinue)
        }
        let continuation1a = { () -> ContinuationResult in
            XCTAssertTrue(fulfillCount == 1, "Messages in wrong order at continuation 2a")
            fulfillCount += 1
            expectation0.fulfill()
            return ContinuationResult.done(.canContinue)
        }
        let continuation2 = { ContinuationResult.more(continuation1) }
        let continuation2a = { () -> ContinuationResult in ContinuationResult.more(continuation1a)}
        let continuation3 = { ContinuationResult.afterThen(.more(continuation2), .more(continuation2a)) }
        let continuation4 = { ContinuationResult.more(continuation3) }
        let continuation4a = { () -> ContinuationResult in
            XCTAssertTrue(fulfillCount == 2, "Messages in wrong order at continuation 4a")
            fulfillCount += 1
            expectation1.fulfill()
            return ContinuationResult.done(.canContinue)
        }
        let continuation5 = { ContinuationResult.afterThen(.more(continuation4), .more(continuation4a)) }
        let continuation6 = { ContinuationResult.more(continuation5) }
        let continuation7 = { ContinuationResult.more(continuation6) }
        let result = ContinuationResult.complete(.more(continuation7))
        switch result {
        case .done(let termination):
            switch termination {
            case .canContinue: ()
            default:
                XCTFail("bad return from done")
            }
        default:
            XCTFail("did not complete")
        }
        waitForExpectations(timeout: 10.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }

    enum ContinuationTestError: Error {
        case test(String)
    }
    
    func testErrorChaining() {
        let expectation0 = self.expectation(description: "Complete Path 1 processing")
        let expectation1 = self.expectation(description: "Complete Path 2 processing")
        let expectation2 = self.expectation(description: "Complete Path 3 processing")
        let expectation3 = self.expectation(description: "Complete Path 3 processing")
        var fulfillCount = 0
        
        let continuation1 = { (_: Int?) throws -> ContinuationResult in
            XCTAssertTrue(fulfillCount == 0, "Messages in wrong order at continuation 1")
            fulfillCount += 1
            expectation0.fulfill()
            return ContinuationResult.done(.canContinue)
        }
        let continuation1a = { (_: Int?) throws -> ContinuationResult in
            XCTAssertTrue(fulfillCount == 1, "Messages in wrong order at continuation 1a")
            fulfillCount += 1
            expectation1.fulfill()
            return ContinuationResult.done(.canContinue)
        }
        let continuation2 = { (value: Int?) throws -> ContinuationResult in
            throw ContinuationErrorContext(
                opType: .map, value: value, delivery: continuation1, error: ContinuationTestError.test("continuation2") )
        }
        let continuation2a = { (_: Int?) throws -> ContinuationResult in ContinuationResult.more({try continuation1a(nil)}) }
        let continuation3 = { (_: Int?) throws -> ContinuationResult in
            ContinuationResult.afterThen(.more({try continuation2(nil)}), .more({ try continuation2a(nil) }))
        }
        let continuation4 = { (_: Int?) throws -> ContinuationResult in ContinuationResult.more({try continuation3(nil)}) }
        let continuation4a = { (_: Int?) throws -> ContinuationResult in
            XCTAssertTrue(fulfillCount == 2, "Messages in wrong order at continuation 4a")
            fulfillCount += 1
            expectation2.fulfill()
            return ContinuationResult.done(.canContinue)
        }
        let continuation5 = { (_: Int?) throws -> ContinuationResult in
            ContinuationResult.afterThen(.more({ try continuation4(nil) }), .more({ try continuation4a(nil)}))
        }
        let continuation6 = { (_: Int?) throws -> ContinuationResult in
            ContinuationResult.more({try continuation5(nil)})
        }
        let continuation7 = { (_: Int?) throws -> ContinuationResult in
            ContinuationResult.more({try continuation6(nil)})
        }
        
        // Attach an error handler that will active in continuation2, i.e. 5 levels away, all processing
        // should continue normally and all expectations should still fulfill
        let driver = { () throws -> ContinuationResult in try continuation7(nil) }
        let outcome = ContinuationResult.complete(.more(driver)) { (context: ContinuationErrorContextProtocol) -> ContinuationResult in
            guard let context = context as? ContinuationErrorContext<Int?, Int> else {
                XCTFail("Received unhandleable error")
                return .done(.canContinue)
            }
            guard let error = context.error as? ContinuationTestError,
                case .test(let message) = error,
                context.opType == .map,
                message == "continuation2"
                else {
                    XCTFail("Error from wrong location")
                    return .done(.canContinue)
                }
            return .more({try context.delivery(context.value)})
        }
        
        XCTAssertTrue(fulfillCount == 3, "Messages in wrong order at continuation 7")
        fulfillCount += 1
        expectation3.fulfill()
        
        switch outcome {
        case .done: ()
        default:
            XCTFail("Finished undone")
        }
        waitForExpectations(timeout: 10.0) { (error) in XCTAssertNil(error, "Timeout waiting for completion") }
    }
}
