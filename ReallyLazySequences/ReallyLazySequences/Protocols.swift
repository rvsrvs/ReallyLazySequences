//
//  ReallyLazySequenceProtocols.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

public typealias Continuation = () -> Any?

public protocol TaskProtocol {
    func start(_ completionHandler: (TaskProtocol) -> Void)
}

// Consumers allow new values to be pushed into a ReallyLazySequence
public protocol ConsumerProtocol {
    associatedtype PushableType
    func push(_ value: PushableType?) throws -> Void
}

public protocol ProducerProtocol {
    associatedtype SequentialType // The type which is output from a given RLS
    func consume(_ delivery: @escaping (SequentialType?) -> Void) -> TaskProtocol
}

public protocol ReallyLazySequenceProtocol {
    associatedtype HeadType // The type which can be input for a given RLS
    associatedtype SequentialType // The type which is output from a given RLS
    
    typealias PushFunction = (HeadType?) throws -> Void // a function to allow input to an RLS
    typealias ConsumerFunction = (SequentialType?) -> Continuation  // a function which consumes the output of an RLS
    
    // To be used, ReallyLazySequences must be first consumed. 
    // Consumation uses compose to create a function which accepts input of HeadType and outputs SequentialType
    func consume(_ delivery: @escaping (SequentialType?) -> Void) -> Consumer<Self>
    func compose(_ output: @escaping ConsumerFunction) -> PushFunction
    
    // swift.Sequence replication 
    // in Swift 4 these will all return ChainedSequence where PredecessorType == Self && SequentialType = T (or Self.SequentialType)
    func map<T>(_ transform: @escaping (SequentialType) -> T ) -> Map<Self, T>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, SequentialType) -> T ) -> Reduce<Self, T>
    func filter(_ filter: @escaping (SequentialType) -> Bool ) -> Filter<Self, SequentialType>
    func sort(_ comparison: @escaping (SequentialType, SequentialType) -> Bool ) -> Sort<Self, SequentialType>
}

// The protocol allowing chaining of sequences.  Reminiscent of LazySequence
public protocol ChainedSequence: ReallyLazySequenceProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    typealias Composer = (@escaping (SequentialType?) -> Continuation) -> ((PredecessorType.SequentialType?) -> Continuation)
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
}


