//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
    
    var successful: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
}

public enum ReallyLazySequenceError: Error {
    case isComplete
    case nonPushable
    case noListeners
    
    var description: String {
        switch self {
        case .isComplete:
            return "ReallyLazySequence has already completed.  Pushes not allowed"
        case .nonPushable:
            return "push may only be called on Sequences which are NOT already attached to producers"
        case .noListeners:
            return "No listeners available for producer to produce into"
        }
    }
}

public protocol ReallyLazySequenceProtocol {
    associatedtype InputType  // The _initial_ initial type for the head for a given RLS chain
    associatedtype OutputType // The type which is output from a given RLS
    
    // a function to allow input to an RLS
    typealias InputDelivery  = (Self.InputType?) throws -> ContinuationResult
    // a function which consumes the output of an RLS and returns a function to execute the successor RLS
    typealias ContinuableOutputDelivery = (OutputType?) -> ContinuationResult
    // a function which consumes the output of an RLS and returns nothing.  This is the type
    // we provide to consumers of the RLS API
    typealias TerminalOutputDelivery = (OutputType?) -> Void

    // To be used, ReallyLazySequences must be first consumed.
    // consume uses compose to create a function which accepts input of InputType
    // and outputs OutputType.  The main purpose of an RLS is to compose
    // its function for a consumer.
    func compose(_ output: @escaping ContinuableOutputDelivery) -> InputDelivery

    // All RLS successor chains, to be used, eventually terminate in a Consumer or a listen
    // consume hands back an object which can be subsequently used
    func consume(_ delivery: @escaping TerminalOutputDelivery) -> Consumer<Self>
    
    // listen assumes that the head end of the chain is a reference type and that the
    // user of the framework already has that reference
    func listen(_ delivery: @escaping TerminalOutputDelivery) -> Void
    
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
    func flatMap<T, U>(queue: OperationQueue?, _ transform: @escaping (OutputType) -> U) -> FlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
    
    /*
     Swift.Sequence replication
     */
    // each of these returns a different concrete type meeting the ChainedSequenceProtocol
    // All returned types differ only in name, allowing the path through the sequence to
    // be read from the type name itself
    func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) -> T? ) -> CompactMap<Self, T>
    func flatMap<T, U>(_ transform: @escaping (OutputType) -> U) -> FlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
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
    typealias PredecessorContinuableOutputDelivery = (PredecessorType.OutputType?) -> ContinuationResult
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorContinuableOutputDelivery
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

// Head struct in a sequence.  Note that it has NO predecessor and
// and does no real work.  It simply allows a value to enter a chain of computation.
// All RLS predecessor chains evenutally termiante in a struct which meets the RLS protocol,
// but which does NOT meet the ChainedSequenceProtocol.  Examples of such structs provided
// by the framework include: SimpleSequence, GeneratingSequence and ListenableSequence
// Each RLS/non-Chained struct must provide its own compose method which must properly
// interoperate with the continuation flow expected by consumers and listeners
// NB. T cannot be Void
public struct SimpleSequence<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    public init() { }    
}

public protocol SubsequenceProtocol: ReallyLazySequenceProtocol {
    var generator: (InputType, @escaping (OutputType?) -> Void) -> Void { get set }
    init(_ generator: @escaping (InputType, @escaping (OutputType?) -> Void) -> Void)
}

public extension SubsequenceProtocol {
    func compose(_ delivery: @escaping ContinuableOutputDelivery) -> InputDelivery {
        let deliveryWrapper = { (output: OutputType?) -> Void in
            _ = ContinuationResult.complete(delivery(output));
            return
        }
        return { (input: InputType?) throws -> ContinuationResult in
            guard let input = input else { return delivery(nil) }
            return .more ({ self.generator(input, deliveryWrapper); return ContinuationResult.done })
        }
    }
}

public struct GeneratingSequence<T, U>: SubsequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = U
    public var generator: (T, @escaping (U?) -> Void) -> Void
    
    public init(_ generator: @escaping (T, @escaping (U?) -> Void) -> Void) {
        self.generator = generator
    }
}
