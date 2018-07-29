//
//  ReallyLazySequenceProtocols.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public typealias Continuation = () -> Any?

public protocol ReallyLazySequenceProtocol {
    associatedtype InputType  // The type which can be input for a given RLS
    associatedtype OutputType // The type which is output from a given RLS
    
    typealias InputFunction  = (InputType?) throws -> Void    // a function to allow input to an RLS
    typealias OutputFunction = (OutputType?) -> Continuation  // a function which consumes the output of an RLS
    
    // To be used, ReallyLazySequences must be first consumed. 
    // Consumation uses compose to create a function which accepts input of InputType and outputs OutputType
    func compose(_ output: @escaping OutputFunction) -> InputFunction
    func consume(_ delivery: @escaping OutputFunction) -> Consumer<Self>
    
    // Useful RLS-only functions
    func dispatch(_ queue: OperationQueue) -> Dispatch<Self, OutputType>
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) -> T,
        until: @escaping (T) -> Bool
    ) -> Collect<Self, T>
    
    // swift.Sequence replication
    // each of these returns a different concrete type meeting the ChainedSequenceProtocol
    // All returned types differ only in name
    func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T>
    func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<T>) -> FlatMap<Self, T>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) -> T ) -> Reduce<Self, T>
    func filter(_ filter: @escaping (OutputType) -> Bool ) -> Filter<Self, OutputType>
    func sort(_ comparison: @escaping (OutputType, OutputType) -> Bool ) -> Sort<Self, OutputType>
}

// Consumers allow new values to be pushed into a ReallyLazySequence
public protocol ConsumerProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    func push(_ value: PredecessorType.InputType?) throws -> Void
}

public protocol TaskProtocol {
    var isStarted: Bool { get }
    var isCompleted: Bool { get }
    func start() throws -> Void
}

// The protocol allowing chaining of sequences.  Reminiscent of LazySequence
public protocol ChainedSequence: ReallyLazySequenceProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    typealias PredecessorOutputFunction = (PredecessorType.OutputType?) -> Continuation
    typealias Composer = (@escaping OutputFunction) -> PredecessorOutputFunction
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
}


