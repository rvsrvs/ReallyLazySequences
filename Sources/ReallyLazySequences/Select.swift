//
//  Select.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/29/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public func select<T0, T1>(_ t0: T0, _ t1: T1) -> Select2<T0, T1> where
    T0: ReallyLazySequenceProtocol,
    T1: ReallyLazySequenceProtocol {
        return Select2(t0, t1)
}

public struct Select2<T0, T1>: ReallyLazySequenceProtocol
    where T0: ReallyLazySequenceProtocol, T1: ReallyLazySequenceProtocol {
    public typealias InputType = (T0.InputType?, T1.InputType?)
    public typealias OutputType = (T0.OutputType?, T1.OutputType?)
    
    public var description: String
    
    var s0: T0
    var s1: T1
    
    init(_ s0: T0, _ s1: T1) {
        self.s0 = s0
        self.s1 = s1
        self.description = standardizeRLSDescription("Select2<\n\t\(s0.description),\n\t\(s1.description)\n>")
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
