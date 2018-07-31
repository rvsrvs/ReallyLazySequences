//
//  Continuation.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

// Continuations represent at computation which can be continued at a later time
// They are a way of avoiding enormous convoluted stack frames that emerge from
// composing a chain of functions in an RLS.  They continue the current computation
// in a stack frame much closer to the users invocation
public typealias Continuation = () -> Any?

let ContinuationDone = { nil } as Continuation

func drive(_ continuation: Continuation) -> Void {
    var next = continuation(); while let current = next as? Continuation { next = current() }
}
