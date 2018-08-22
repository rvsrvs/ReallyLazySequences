//
//  Consumer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

// The termination of any RLS successor chain
// Only Consumers invoke the initial compose function, which creates the
// push closure. Only consumers can be "pushed" to because of this.
// Once consumed an RLS can no longer be chained.
// Consumers can only be initialized and pushed to.
// i.e. consumers are NOT RLS's
import Foundation

public protocol ConsumableSequenceProtocol: ReallyLazySequenceProtocol {
    // All RLS successor chains, to be used, eventually terminate in a Consumer or a listen
    // consume hands back an object which can be subsequently used
    func consume(_ delivery: @escaping (Self.OutputType?) -> Void) -> Consumer<Self.InputType>
    
    // Dispatch into an operation queue and drive the dispatch all the way through
    // unlike Swift.Sequence, downstream operations may occur on separate queues
    func dispatch(_ queue: OperationQueue) -> ConsumableDispatch<Self, OutputType>
    
    // Batch up values until a condition is met and then release the values
    // This is a generalized form of reduce
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ConsumableReduce<Self, T>
    
    // Flatmap and optionally dispatch the producers into an OpQueue to allow them to be parallelized
    func flatMap<T, U>(queue: OperationQueue?, _ transform: @escaping (OutputType) throws -> U) -> ConsumableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
    
    /*
     Swift.Sequence replication
     */
    // each of these returns a different concrete type meeting the ChainedSequenceProtocol
    // All returned types differ only in name, allowing the path through the sequence to
    // be read from the type name itself
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ConsumableMap<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ConsumableCompactMap<Self, T>
    func flatMap<T, U>(_ transform: @escaping (OutputType) throws -> U) -> ConsumableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ConsumableReduce<Self, T>
    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ConsumableFilter<Self, OutputType>
}

// The protocol allowing chaining of sequences.  Reminiscent of LazySequence
// ChainedSequences compose their predecessor's action (e.g. map, collect, flatmap, filter)
// with their own when asked to do so by a consumer.
// NB a Consumer retains ONLY the composed function and not the actual sequence object,
// though Consumer types are genericized with the chain of types leading up to consumption
public protocol ConsumableChainedSequence: ConsumableSequenceProtocol {
    associatedtype PredecessorType: ConsumableSequenceProtocol
    typealias PredecessorContinuableOutputDelivery = (PredecessorType.OutputType?) -> ContinuationResult
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorContinuableOutputDelivery
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

public protocol ConsumerProtocol: CustomStringConvertible {
    associatedtype InputType
    var composition: (InputType?) throws -> ContinuationResult { get }
    func process(_ value: InputType?) throws -> ContinuationResult
}

public extension ConsumerProtocol {
    // Accept a push of the Head type and pass it through the composed closure
    public func process(_ value: InputType?) throws -> ContinuationResult { return try composition(value) }
}

public struct Consumer<T>: ConsumerProtocol {
    public typealias InputType = T

    public var description: String
    // NB Predecessor.InputType is the type of the head of the sequence,
    // NOT the specific output type for the Predecessor's Predecessor
    private(set) public var composition: (InputType?) throws -> ContinuationResult
    
    public init<Predecessor>(predecessor:Predecessor, delivery: @escaping ((Predecessor.OutputType?) -> Void))
        where Predecessor: ReallyLazySequenceProtocol, Predecessor.InputType == T {
        self.description = "\(predecessor.description) >> Consumer<\(type(of:InputType.self))>"
                .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")
        var isComplete = false
        
        let deliveryWrapper = { (value: Predecessor.OutputType?) -> ContinuationResult in
            delivery(value)
            return .done
        }
        // Have the predecessor compose its operation with ours
        // Different types of predecessors compose differently
        // This call eventually recurses through all predecessors
        // terminating at an RLS structure.
        let predecessorComposition = predecessor.compose(deliveryWrapper)
        
        // Consumer composes the final push function here.
        composition = { value in
            guard !isComplete else { throw ReallyLazySequenceError.isComplete }
            if value == nil { isComplete = true }
            var result: ContinuationResult = .done
            do {
                result = ContinuationResult.complete(try predecessorComposition(value))
            } catch {
                print(error)
            }
            return result
        }
    }
}
