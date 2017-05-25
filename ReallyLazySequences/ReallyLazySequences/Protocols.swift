//
//  ReallyLazySequenceProtocols.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

public typealias Continuation = () -> Any?

public protocol TaskProtocol {
    func start(_ completionHandler: @escaping (TaskProtocol) -> Void)
}

// Consumers allow new values to be pushed into a ReallyLazySequence
public protocol ConsumerProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    func push(_ value: PredecessorType.HeadType?) throws -> Void
}

public protocol ProducerProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    var produce: (PredecessorType.PushFunction) throws -> Void { get }
    func consume(_ delivery: @escaping (PredecessorType.ConsumableType?) -> Void) -> Task<PredecessorType>
}

public protocol ReallyLazySequenceProtocol {
    associatedtype HeadType // The type which can be input for a given RLS
    associatedtype ConsumableType // The type which is output from a given RLS
    
    typealias PushFunction = (HeadType?) throws -> Void // a function to allow input to an RLS
    typealias ConsumerFunction = (ConsumableType?) -> Continuation  // a function which consumes the output of an RLS
    
    // To be used, ReallyLazySequences must be first consumed. 
    // Consumation uses compose to create a function which accepts input of HeadType and outputs ConsumableType
    func compose(_ output: @escaping ConsumerFunction) -> PushFunction
    func consume(_ delivery: @escaping (ConsumableType?) -> Void) -> Consumer<Self>
    func produce(_ input: @escaping (PushFunction) throws -> Void) -> Producer<Self>
    
    // swift.Sequence replication 
    // in Swift 4 these will all return ChainedSequence where PredecessorType == Self && ConsumableType = T (or Self.ConsumableType)
    func map<T>(_ transform: @escaping (ConsumableType) -> T ) -> Map<Self, T>
//    func flatMap(_ transform: @escaping (ConsumableType) -> ConsumableType?) -> FlatMapOptional<Self, ConsumableType>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, ConsumableType) -> T ) -> Reduce<Self, T>
    func filter(_ filter: @escaping (ConsumableType) -> Bool ) -> Filter<Self, ConsumableType>
    func sort(_ comparison: @escaping (ConsumableType, ConsumableType) -> Bool ) -> Sort<Self, ConsumableType>
}

// The protocol allowing chaining of sequences.  Reminiscent of LazySequence
public protocol ChainedSequence: ReallyLazySequenceProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    typealias Composer = (@escaping (ConsumableType?) -> Continuation) -> ((PredecessorType.ConsumableType?) -> Continuation)
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
}


