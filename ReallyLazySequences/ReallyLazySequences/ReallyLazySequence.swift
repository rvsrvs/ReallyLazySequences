//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

enum ReallyLazySequenceError: Error {
    case isComplete
    
    var description: String {
        switch self {
        case .isComplete:
            return "ReallyLazySequence has already completed.  Pushes not allowed"
        }
    }
}

public struct Task<Predecessor: ReallyLazySequenceProtocol>: TaskProtocol {
    private let producer: Producer<Predecessor>
    private let consumer: Consumer<Predecessor>
    
    public init(producer: Producer<Predecessor>, consumer: Consumer<Predecessor>) {
        self.producer = producer
        self.consumer = consumer
    }
    
    public func start(_ completionHandler: @escaping (TaskProtocol) -> Void) {
        producer.starter { (input: Consumer<Predecessor>.PushableType?) -> Void in
            guard let input = input else {
                try? consumer.push(nil)
                completionHandler(self)
                return
            }
            try? consumer.push(input)
        }
    }
}

public struct Consumer<Predecessor: ReallyLazySequenceProtocol>: ConsumerProtocol {
    public typealias PushableType = Predecessor.HeadType
    
    private let _push: (PushableType?) throws -> Void
    
    init(predecessor:Predecessor, delivery: @escaping ((Predecessor.ConsumableType?) -> Void)) {
        var isComplete = false
        let deliveryWrapper = { (value: Predecessor.ConsumableType?) -> Continuation in
            if value == nil { isComplete = true }
            return { delivery(value); return nil }
        }
        let composition = predecessor.compose(deliveryWrapper)
        _push = { (value:PushableType?) throws -> Void in
            guard !isComplete else { throw ReallyLazySequenceError.isComplete }
            try composition(value)
        }
    }
    
    public func push(_ value: PushableType?) throws -> Void { try _push(value) }
}

public struct ReallyLazySequence<T>: ReallyLazySequenceProtocol {
    public typealias HeadType = T
    public typealias ConsumableType = T
    public func compose(_ output: @escaping (ConsumableType?) -> Continuation) -> ((HeadType?) throws -> Void) {
        return { (value: HeadType?) -> Void in
            var nextDelivery: Continuation? = output(value)
            while nextDelivery != nil { nextDelivery = nextDelivery!() as? Continuation }
        }
    }
}

// Template struct for chaining. 
public struct ReallyLazyChainedSequence<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias HeadType = Predecessor.HeadType
    public typealias ConsumableType = Output
    
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
    public typealias HeadType = Predecessor.HeadType
    public typealias ConsumableType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Reduce<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias HeadType = Predecessor.HeadType
    public typealias ConsumableType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Filter<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias HeadType = Predecessor.HeadType
    public typealias ConsumableType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Sort<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias HeadType = Predecessor.HeadType
    public typealias ConsumableType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}
