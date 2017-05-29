//
//  ReallyLazySequenceProtocols.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

public typealias Continuation = () -> Any?

public protocol ReallyLazySequenceProtocol {
    associatedtype InputType // The type which can be input for a given RLS
    associatedtype OutputType // The type which is output from a given RLS
    
    typealias PushFunction = (InputType?) throws -> Void // a function to allow input to an RLS
    typealias ConsumerFunction = (OutputType?) -> Continuation  // a function which consumes the output of an RLS
    
    // To be used, ReallyLazySequences must be first consumed. 
    // Consumation uses compose to create a function which accepts input of InputType and outputs OutputType
    func compose(_ output: @escaping ConsumerFunction) -> PushFunction
    func consume(_ delivery: @escaping (OutputType?) -> Void) -> Consumer<Self>
    func produce(_ input: @escaping (PushFunction) throws -> Void) -> Producer<Self>
    
    // swift.Sequence replication 
    // in Swift 4 these will all return ChainedSequence where PredecessorType == Self && OutputType = T (or Self.OutputType)
    func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T>
    func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<ReallyLazySequence<T>>) -> FlatMapSequence<Self, T>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) -> T ) -> Reduce<Self, T>
    func filter(_ filter: @escaping (OutputType) -> Bool ) -> Filter<Self, OutputType>
    func sort(_ comparison: @escaping (OutputType, OutputType) -> Bool ) -> Sort<Self, OutputType>
}

// The protocol allowing chaining of sequences.  Reminiscent of LazySequence
public protocol ChainedSequence: ReallyLazySequenceProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    typealias Composer = (@escaping (OutputType?) -> Continuation) -> ((PredecessorType.OutputType?) -> Continuation)
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
}

// Consumers allow new values to be pushed into a ReallyLazySequence
public protocol ConsumerProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    func push(_ value: PredecessorType.InputType?) throws -> Void
    func produce(_ handler: @escaping (PredecessorType.PushFunction) throws -> Void) -> Task<PredecessorType>
}

public protocol ProducerProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    var produce: (PredecessorType.PushFunction) throws -> Void { get }
    func consume(_ delivery: @escaping (PredecessorType.OutputType?) -> Void) -> Task<PredecessorType>
}

public protocol TaskProtocol {
    func start(_ completionHandler: @escaping (TaskProtocol) -> Void)
}




