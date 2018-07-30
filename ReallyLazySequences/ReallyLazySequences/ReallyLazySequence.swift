//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

let ContinuationDone = { nil } as Continuation

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

//Head struct in a sequence.  Note that it has NO predecessor
public struct ReallyLazySequence<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
}

// A sequence with an attached consumer function.
// Only consumers invoke the initial compose function, which creates the
// push closure. Only consumers can be pushed to because of this.
// Once consumed an RLS can no longer be chained.  i.e. consumers are NOT RLS's
public struct Consumer<Predecessor: ReallyLazySequenceProtocol>: ConsumerProtocol {
    public typealias PredecessorType = Predecessor // Required for ConsumerProtocol
    
    private let predecessor: Predecessor
    private let _push: (Predecessor.InputType?) throws -> Void // Predecessor Input type is the type of the head of the sequence
    
    init(predecessor:Predecessor, delivery: @escaping ((Predecessor.OutputType?) -> Continuation)) {
        self.predecessor = predecessor
        var isComplete = false
        
        // deliveryWrapper is the closure that our predecessor will use to deliver values to us
        // These values delivered of course must match the Predecessor's OutputType
        let deliveryWrapper = { (value: Predecessor.OutputType?) -> Continuation in
            if value == nil { isComplete = true }
            return { return delivery(value) }
        }
        
        // Have the predecessor compose its operation with ours
        // Different types of predecessors compose differently
        // This call recurses through all predecessors
        let composition = predecessor.compose(deliveryWrapper)

        // Consumer composes the final push function here.
        _push = { (value:Predecessor.InputType?) throws -> Void in
            guard !isComplete else { throw ReallyLazySequenceError.isComplete }
            try composition(value)
        }
    }
    
    // Accept a push of the Head type and pass it through the composed closure
    public func push(_ value: Predecessor.InputType?) throws -> Void {
        guard Predecessor.InputType.self != Void.self else { throw ReallyLazySequenceError.nonPushable }
        try _push(value)
    }
}

public struct Producer<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    public typealias ProducerConsumer = Consumer<Producer<T>>
    
    public class Task: TaskProtocol {
        private(set) public var isStarted = false
        private(set) public var isCompleted = false
        private var consumer: ProducerConsumer!
        
        init(_ producer: Producer<T>, _ delivery: @escaping OutputFunction) {
            let composedDelivery = { (value: OutputType?) -> Continuation in
                if value == nil { self.isCompleted = true }
                return delivery(value)
            }
            self.consumer = producer.consume(composedDelivery)
        }
        
        public func start() throws -> Void {
            guard !isStarted else { throw ReallyLazySequenceError.nonPushable }
            isStarted = true
            try consumer.push(nil)
        }
    }
    
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
    
    public func task(_ delivery: @escaping OutputFunction) -> TaskProtocol {
        return Task(self, delivery)
    }
}

