//
//  Consumer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

// The termination of any RLS successor chain
// Only Consumers invoke the initial compose function, which creates the
// push closure. Only consumers can be "pushed" to because of this.
// Once consumed an RLS can no longer be chained.
// Consumers can only be initialized and pushed to.
// i.e. consumers are NOT RLS's
import Foundation

public protocol ConsumerProtocol {
    associatedtype InputType
    func push(_ value: InputType?) throws -> Void
}

public struct Consumer<Predecessor: ReallyLazySequenceProtocol>: ConsumerProtocol {
    public typealias InputType = Predecessor.InputType
    public let predecessor: Predecessor
    // NB Predecessor.InputType is the type of the head of the sequence,
    // NOT the specific output type for the Predecessor's Predecessor
    private let _push: (Predecessor.InputType?) throws -> Void
    
    public init(predecessor:Predecessor, delivery: @escaping ((Predecessor.OutputType?) -> Void)) {
        self.predecessor = predecessor
        var isComplete = false
        
        let deliveryWrapper = { (value: Predecessor.OutputType?) -> Continuation in
            delivery(value)
            return ContinuationDone
        }
        // Have the predecessor compose its operation with ours
        // Different types of predecessors compose differently
        // This call eventually recurses through all predecessors
        // terminating at an RLS structure.
        let composition = predecessor.compose(deliveryWrapper)
        
        // Consumer composes the final push function here.
        _push = { value in
            guard !isComplete else { throw ReallyLazySequenceError.isComplete }
            if value == nil { isComplete = true }
            try composition(value)
        }
    }
    
    // Accept a push of the Head type and pass it through the composed closure
    //
    public func push(_ value: Predecessor.InputType?) throws -> Void {
        guard Predecessor.InputType.self != Void.self else { throw ReallyLazySequenceError.nonPushable }
        try _push(value)
    }
    
    // Accept a push of a closure which
    public func push(
        queue: OperationQueue? = nil,
        _ producer: @escaping ((Predecessor.InputType?) throws-> Void) throws-> Void
        ) throws -> Void {
        guard Predecessor.InputType.self != Void.self else { throw ReallyLazySequenceError.nonPushable }
        if let queue = queue {
            queue.addOperation {
                try? producer(self._push)
            }
        } else {
            do {
                try producer(self._push)
            } catch {
                throw error
            }
        }
    }
}
