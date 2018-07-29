//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

enum ReallyLazySequenceError: Error {
    case isComplete
    case nonPushable
    var description: String {
        switch self {
        case .isComplete:
            return "ReallyLazySequence has already completed.  Pushes not allowed"
        case .nonPushable:
            return "push may only be called on Sequences which are NOT already attached to producers"
        }
    }
}

//Head struct in a sequence
public struct ReallyLazySequence<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
}

//A sequence with an attached consumer function.  Only consumers can be pushed to
public struct Consumer<Predecessor: ReallyLazySequenceProtocol>: ConsumerProtocol {
    public typealias PredecessorType = Predecessor
    
    private let predecessor: Predecessor
    private let _push: (Predecessor.InputType?) throws -> Void
    
    init(predecessor:Predecessor, delivery: @escaping ((Predecessor.OutputType?) -> Continuation)) {
        self.predecessor = predecessor
        var isComplete = false
        let deliveryWrapper = { (value: Predecessor.OutputType?) -> Continuation in
            if value == nil { isComplete = true }
            return { return delivery(value) }
        }
        let composition = predecessor.compose(deliveryWrapper)
        _push = { (value:Predecessor.InputType?) throws -> Void in
            guard !isComplete else { throw ReallyLazySequenceError.isComplete }
            try composition(value)
        }
    }
    
    public func push(_ value: Predecessor.InputType?) throws -> Void {
        if Predecessor.InputType.self == Void.self {
            throw ReallyLazySequenceError.nonPushable
        } else {
            try _push(value)
        }
    }
}

public struct Producer<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    public var produce: (@escaping (T?) -> Void) throws -> Void
    
    public init(_ produce:  @escaping ((T?) -> Void) throws -> Void) {
        self.produce = produce
    }
    
    public func compose(_ output: (@escaping (T?) -> Continuation)) -> ((T?) throws -> Void) {
        var completed = false
        return { (value: T?) throws -> Void in
            guard value == nil else { throw ReallyLazySequenceError.nonPushable }
            guard !completed else { throw ReallyLazySequenceError.isComplete }
            completed = true
            let wrappedOutput = { (value: T?) -> Void in
                var nextDelivery: Continuation? = output(value)
                while nextDelivery != nil { nextDelivery = nextDelivery!() as? Continuation }
                return
            }
            try self.produce(wrappedOutput)
        }
    }
}
