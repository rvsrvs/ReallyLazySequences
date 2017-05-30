//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

enum ReallyLazySequenceError: Error {
    case isComplete
    case nonStartable
    case nonPushable
    var description: String {
        switch self {
        case .isComplete:
            return "ReallyLazySequence has already completed.  Pushes not allowed"
        case .nonStartable:
            return "start may only be called on Sequences with attached Producers"
        case .nonPushable:
            return "push may only be called on Sequences which are NOT already attached to producers"
        }
    }
}

public struct ReallyLazySequence<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    public func compose(_ output: @escaping (OutputType?) -> Continuation) -> ((InputType?) throws -> Void) {
        return { (value: InputType?) -> Void in
            var nextDelivery: Continuation? = output(value)
            while nextDelivery != nil { nextDelivery = nextDelivery!() as? Continuation }
        }
    }
}

public struct Producer<T>: ReallyLazySequenceProtocol {
    public typealias InputType = Void
    public typealias OutputType = T
    public var produce: (OutputFunction) -> InputFunction
    
    public init(_ produce: @escaping (OutputFunction) -> InputFunction) {
        self.produce = produce
    }
    
    public func compose(_ output: @escaping OutputFunction) -> InputFunction {
        var completed = false
        return { (value: InputType?) throws -> Void in
            guard !completed else { throw ReallyLazySequenceError.isComplete }
            completed = true
            let wrappedOutput = { (value: OutputType?) -> Continuation in
                var nextDelivery: Continuation? = output(value)
                while nextDelivery != nil { nextDelivery = nextDelivery!() as? Continuation }
                return { nil }
            }
            try self.produce(wrappedOutput)(())
        }
    }
}

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

    public func start() throws -> Void {
        if Predecessor.InputType.self != Void.self {
            throw ReallyLazySequenceError.nonPushable
        } else {
            let value: Predecessor.InputType? = .none
            try _push(value)
        }
    }
}

// Template struct for chaining.
public struct ReallyLazyChainedSequence<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

//===================================================================================
// structs for Chaining
public struct Map<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Reduce<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Filter<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Sort<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct FlatMapSequence<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}
