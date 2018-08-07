//
//  ListenerTests.swift
//  ReallyLazySequencesTests
//
//  Created by Van Simmons on 8/6/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import XCTest
@testable import ReallyLazySequences

class ListenerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testListenableValue() {
        let testValue = ListenableValue<Int>(2)
        testValue
            .listener()
            .map {  $0 * 2 }
            .listen { (value) in
                if let value = value {
                    print("\(value)")
                }
            }
        testValue.value = 4
    }
}
