//
//  Select.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/29/18.
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

import Foundation

public func select<T0, T1>(_ t0: T0, _ t1: T1) -> Select2<T0, T1> where
    T0: SequenceProtocol,
    T1: SequenceProtocol {
        return Select2(t0, t1)
}

public struct Select2<T0, T1>: SequenceProtocol
    where T0: SequenceProtocol, T1: SequenceProtocol {
    public typealias InputType = (T0.InputType?, T1.InputType?)
    public typealias OutputType = (T0.OutputType?, T1.OutputType?)
    
    public var description: String
    
    var s0: T0
    var s1: T1
    
    init(_ s0: T0, _ s1: T1) {
        self.s0 = s0
        self.s1 = s1
        self.description = Utilities.standardizeDescription("Select2<\n\t\(s0.description),\n\t\(s1.description)\n>")
    }
    
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery? {
        guard let c0 = s0.compose({ (input: T0.OutputType?) -> ContinuationResult in
            let value: OutputType = (input, nil)
            return .more({ delivery(value) })
        }),
        let c1 = s1.compose({ (input: T1.OutputType?) -> ContinuationResult in
            let value: OutputType = (nil, input)
            return .more({ delivery(value) })
        })
        else { return nil }
        
        return { (input: InputType?) -> ContinuationResult in
            guard let input = input else { return .more({ delivery(nil) }) }
            if let input0 = input.0 {
                return try c0(input0)
            }
            if let input1 = input.1 {
                return try c1(input1)
            }
            return .done(.canContinue)
        }
    }
}
