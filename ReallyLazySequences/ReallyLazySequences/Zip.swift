//
//  Zip.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/4/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public struct Zip2<
    S1: ReallyLazySequenceProtocol,
    S2: ReallyLazySequenceProtocol
>: ReallyLazySequenceProtocol {
    
    public typealias InputType = (S1.OutputType?, S2.OutputType?)
    public typealias OutputType = (S1.OutputType?, S2.OutputType?)
    public typealias Consumers = (Consumer<S1>, Consumer<S2>)
    
    private var s1: S1
    private var s2: S2
    private var tuple = Tuple<S1.OutputType, S2.OutputType>()
    
    public init(s1: S1, s2: S2) {
        self.s1 = s1
        self.s2 = s2
    }
    
    public func compose(_ output: @escaping (OutputType?) -> Continuation) -> (InputType?) throws -> Void {
        return tuple.compose(output)
    }
    
    public func consumers() -> Consumers {
        let setter0 = tuple.accessors().setters.0
        let c0 = s1.consume { (value: S1.OutputType?) -> Void in
            guard let value = value else { return }
            setter0(value)
        }
        let setter1 = tuple.accessors().setters.1
        let c1 = s2.consume { (value: S2.OutputType?) -> Void in
            guard let value = value else { return }
            setter1(value)
        }
        return (c0, c1)
    }
}


func zip<S1, T1, S2, T2>(s1: S1, s2: S2) -> ReallyLazySequence<(T1, T2)>
    where S1: ReallyLazySequenceProtocol, S1.OutputType == T1,
          S2: ReallyLazySequenceProtocol, S2.OutputType == T2 {
    return ReallyLazySequence<(T1, T2)>()
}
