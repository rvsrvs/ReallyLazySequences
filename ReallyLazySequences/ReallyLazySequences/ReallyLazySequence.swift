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
    case listenerCompleted
    case noListeners
    
    var description: String {
        switch self {
        case .isComplete:
            return "ReallyLazySequence has already completed.  Pushes not allowed"
        case .nonPushable:
            return "push may only be called on Sequences which are NOT already attached to producers"
        case .listenerCompleted:
            return "Listener is complete"
        case .noListeners:
            return "No listeners available for producer to produce into"
        }
    }
}

public protocol ReallyLazySequenceProtocol {
    associatedtype InputType  // The _initial_ initial type for the head for a given RLS chain
    associatedtype OutputType // The type which is output from a given RLS
    
    // a function to allow input to an RLS
    typealias InputDelivery  = (InputType?) throws -> Void
    // a function which consumes the output of an RLS and returns a function to execute the successor RLS
    typealias ContinuableOutputDelivery = (OutputType?) -> Continuation
    typealias TerminalOutputDelivery = (OutputType?) -> Void

    // To be used, ReallyLazySequences must be first consumed.
    // consume uses compose to create a function which accepts input of InputType
    // and outputs OutputType.  The main purpose of an RLS is to compose
    // its function for a consumer.
    // All RLS successor chains, to be used, eventually terminate in a Consumer
    func compose(_ output: @escaping ContinuableOutputDelivery) -> InputDelivery
    func consume(_ delivery: @escaping TerminalOutputDelivery) -> Consumer<Self>
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
        where U: GeneratorProtocol, U.InputType == Self.OutputType, U.OutputType == T
    
    // swift.Sequence replication
    // each of these returns a different concrete type meeting the ChainedSequenceProtocol
    // All returned types differ only in name
    func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) -> T? ) -> CompactMap<Self, T>
    func flatMap<T, U>(_ transform: @escaping (OutputType) -> U) -> FlatMap<Self, T>
        where U: GeneratorProtocol, U.InputType == Self.OutputType, U.OutputType == T
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
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorOutputFunction
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

public protocol GeneratorProtocol: ReallyLazySequenceProtocol {
    var generator: (InputType, @escaping (OutputType?) -> Void) -> Void { get set }
    init(_ generator: @escaping (InputType, @escaping (OutputType?) -> Void) -> Void)
}

public extension GeneratorProtocol {
    func compose(_ delivery: @escaping ContinuableOutputDelivery) -> InputDelivery {
        let deliveryWrapper = { (output: OutputType?) -> Void in drive(delivery(output)) }
        return { (input: InputType?) throws -> Void in
            guard let input = input else { deliveryWrapper(nil); return }
            self.generator(input, deliveryWrapper)
        }
    }
}

public enum GeneratorControl { case start }

public struct Generator<T>: GeneratorProtocol {
    public typealias InputType = GeneratorControl
    public typealias OutputType = T
    public var generator: (InputType, @escaping (T?) -> Void) -> Void
    
    public init(_ generator: @escaping (InputType, @escaping (T?) -> Void) -> Void) {
        self.generator = generator
    }
}

public struct SubsequenceGenerator<T, U>: GeneratorProtocol {
    public typealias InputType = T
    public typealias OutputType = U
    public var generator: (T, @escaping (U?) -> Void) -> Void
    
    public init(_ generator: @escaping (T, @escaping (U?) -> Void) -> Void) {
        self.generator = generator
    }
}


