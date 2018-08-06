//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public enum ReallyLazySequenceError: Error {
    case isComplete
    case nonPushable
    case listenerCompleted
    
    var description: String {
        switch self {
        case .isComplete:
            return "ReallyLazySequence has already completed.  Pushes not allowed"
        case .nonPushable:
            return "push may only be called on Sequences which are NOT already attached to producers"
        case .listenerCompleted:
            return "listener is complete"
        }
    }
}

public protocol ReallyLazySequenceProtocol {
    associatedtype InputType  // The _initial_ initial type for the head for a given RLS chain
    associatedtype OutputType // The type which is output from a given RLS
    
    // a function to allow input to an RLS
    typealias InputFunction  = (InputType?) throws -> Void
    // a function which consumes the output of an RLS and returns a function to execute the successor RLS
    typealias OutputFunction = (OutputType?) -> Continuation
    typealias ConsumerFunction = (OutputType?) -> Void

    // To be used, ReallyLazySequences must be first consumed.
    // consume uses compose to create a function which accepts input of InputType
    // and outputs OutputType.  The main purpose of an RLS is to compose
    // its function for a consumer.
    // All RLS successor chains, to be used, eventually terminate in a Consumer
    func compose(_ output: @escaping OutputFunction) -> InputFunction
    func consume(_ delivery: @escaping ConsumerFunction) -> Consumer<Self>
    func listen(_ delivery: @escaping ConsumerFunction) -> Void
    
    /*
     Useful RLS-only functions, not related to Swift.Sequence
    */
    
    // Dispatch into an operation queue and drive the dispatch all the way through
    // unlike Swift.Sequence, downstream operations may occur on separate queues
    func dispatch(_ queue: OperationQueue) -> Dispatch<Self, OutputType>
    
    // Batch up values until a condition is met and then release the values
    // This is a generalized form of reduce
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> Reduce<Self, T>
    
    // Flatmap and optionally dispatch the producers into an OpQueue to allow them to be parallelized
    func flatMap<T>(queue: OperationQueue?, _ transform: @escaping (OutputType) -> Producer<T>) -> FlatMap<Self, T>
    
    // swift.Sequence replication
    // each of these returns a different concrete type meeting the ChainedSequenceProtocol
    // All returned types differ only in name
    func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T>
    //func compactMap<T, U>(_ transform: @escaping (T) -> U ) -> CompactMap<Self, U> where OutputType == T?
    func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<T>) -> FlatMap<Self, T>

    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) -> T) -> Reduce<Self, T>
    func filter(_ filter: @escaping (OutputType) -> Bool ) -> Filter<Self, OutputType>
}

// The protocol allowing chaining of sequences.  Reminiscent of LazySequence
// ChainedSequences compose their predecessor's action (e.g. map, collect, flatmap, filter)
// with their own when asked to do so by a consumer.
// NB a Consumer retains ONLY the composed function and not the actual sequence object,
// though Consumer types are genericized with the chain of types leading up to consumption
public protocol ChainedSequence: ReallyLazySequenceProtocol {
    associatedtype PredecessorType: ReallyLazySequenceProtocol
    typealias PredecessorOutputFunction = (PredecessorType.OutputType?) -> Continuation
    typealias Composer = (@escaping OutputFunction) -> PredecessorOutputFunction
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

// Head struct in a sequence.  Note that it has NO predecessor and
// and does no real work.  It simply allows a value to enter a chain of computation.
// All RLS predecessor chains evenutally termiante in an RLS struct
// NB. T cannot be Void
public struct ReallyLazySequence<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    public init() { }
}

