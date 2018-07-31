//
//  Consumer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

// The termination of any RLS chain
// Only consumers invoke the initial compose function, which creates the
// push closure. Only consumers can be "pushed" to because of this.
// Once consumed an RLS can no longer be chained.
// Consumers can only be initialized and pushed to.
// i.e. consumers are NOT RLS's
public struct Consumer<Predecessor: ReallyLazySequenceProtocol> {
    public typealias PredecessorType = Predecessor // Required for ConsumerProtocol
    
    private let predecessor: Predecessor
    private let _push: (Predecessor.InputType?) throws -> Void // Predecessor Input type is the type of the head of the sequence
    
    public init(predecessor:Predecessor, delivery: @escaping ((Predecessor.OutputType?) -> Continuation)) {
        self.predecessor = predecessor
        var isComplete = false
        
        // deliveryWrapper is the closure that our predecessor will use to deliver values to us
        // These values delivered of course must match the Predecessor's OutputType
        // The wrapper allows us to set the isCompleted flag so that once
        // nil has been pushed into the consumer, no more values may be accepted
        let deliveryWrapper = { (value: Predecessor.OutputType?) -> Continuation in
            if value == nil { isComplete = true }
            return delivery(value)
        }
        
        // Have the predecessor compose its operation with ours
        // Different types of predecessors compose differently
        // This call eventually recurses through all predecessors
        // terminating at an RLS structure.
        let composition = predecessor.compose(deliveryWrapper)
        
        // Consumer composes the final push function here.
        _push = { (value:Predecessor.InputType?) throws -> Void in
            guard !isComplete else { throw ReallyLazySequenceError.isComplete }
            try composition(value)
        }
    }
    
    // Accept a push of the Head type and pass it through the composed closure
    //
    public func push(_ value: Predecessor.InputType?) throws -> Void {
        guard Predecessor.InputType.self != Void.self else { throw ReallyLazySequenceError.nonPushable }
        try _push(value)
    }
}
