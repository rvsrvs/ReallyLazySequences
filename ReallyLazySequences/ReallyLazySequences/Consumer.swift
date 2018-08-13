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
    associatedtype PredecessorType
    var composition: (InputType?) throws -> Void { get }
    func process(_ value: InputType?) throws -> Void
}

public extension ConsumerProtocol {
    // Accept a push of the Head type and pass it through the composed closure
    public func process(_ value: InputType?) throws -> Void {
        try composition(value)
    }

    // Accept a push of a closure which will generate values type type InputType
    public func push(
        queue: OperationQueue? = nil,
        _ producer: @escaping ((InputType?) throws-> Void) throws-> Void
        ) throws -> Void {
        guard InputType.self != Void.self else { throw ReallyLazySequenceError.nonPushable }
        if let queue = queue {
            queue.addOperation { try? producer(self.composition) }
        } else {
            do {
                try producer(self.composition)
            } catch {
                throw error
            }
        }
    }
}

public struct Consumer<Predecessor: ReallyLazySequenceProtocol>: ConsumerProtocol {
    public typealias InputType = Predecessor.InputType
    public typealias PredecessorType = Predecessor

    // NB Predecessor.InputType is the type of the head of the sequence,
    // NOT the specific output type for the Predecessor's Predecessor
    private(set) public var composition: (InputType?) throws -> Void
    
    public init(predecessor:Predecessor, delivery: @escaping ((Predecessor.OutputType?) -> Void)) {
        var isComplete = false
        
        let deliveryWrapper = { (value: Predecessor.OutputType?) -> Continuation in
            delivery(value)
            return ContinuationDone
        }
        // Have the predecessor compose its operation with ours
        // Different types of predecessors compose differently
        // This call eventually recurses through all predecessors
        // terminating at an RLS structure.
        let predecessorComposition = predecessor.compose(deliveryWrapper)
        
        // Consumer composes the final push function here.
        composition = { value in
            guard !isComplete else { throw ReallyLazySequenceError.isComplete }
            if value == nil { isComplete = true }
            try predecessorComposition(value)
        }
    }
}
