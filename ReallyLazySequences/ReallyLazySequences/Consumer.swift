//
//  Consumer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public protocol ConsumableProtocol: ReallyLazySequenceProtocol {
    func consume(_ delivery: @escaping (Self.OutputType?) -> ContinuationTermination) -> Consumer<Self.InputType>
    
    // Consumable chaining
    func dispatch(_ queue: OperationQueue) -> ConsumableDispatch<Self, OutputType>
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ConsumableReduce<Self, T>
    func flatMap<T, U>(queue: OperationQueue?, _ transform: @escaping (OutputType) throws -> U) -> ConsumableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ConsumableMap<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ConsumableCompactMap<Self, T>
    func flatMap<T, U>(_ transform: @escaping (OutputType) throws -> U) -> ConsumableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ConsumableReduce<Self, T>
    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ConsumableFilter<Self, OutputType>
}

public protocol ChainedConsumableProtocol: ConsumableProtocol {
    associatedtype PredecessorType: ConsumableProtocol
    typealias PredecessorContinuableOutputDelivery = (PredecessorType.OutputType?) -> ContinuationResult
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorContinuableOutputDelivery
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

public struct Consumer<T>: Equatable {
    public static func == (lhs: Consumer<T>, rhs: Consumer<T>) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    public var identifier: UUID = UUID()
    public var description: String
    private var composition: (T?) throws -> ContinuationResult
    
    public init(delivery: @escaping (T?) throws -> ContinuationResult) {
        self.description = standardize("Consumer<\(type(of:T.self))>")
        var isComplete = false
        composition = { value in
            guard !isComplete else { throw ReallyLazySequenceError.isComplete }
            if value == nil { isComplete = true }
            do {
                return ContinuationResult.complete(try delivery(value))
            } catch {
                throw error
            }
        }
    }
    
    public init<Predecessor>(predecessor:Predecessor, delivery: @escaping ((Predecessor.OutputType?) -> ContinuationTermination))
        where Predecessor: ReallyLazySequenceProtocol, Predecessor.InputType == T {
        self.description = standardize("\(predecessor.description) >> Consume<\(type(of:Predecessor.OutputType.self))>")
        let deliveryWrapper = { (value: Predecessor.OutputType?) -> ContinuationResult in
            return .done(delivery(value))
        }
        // Have the predecessor compose its operation with ours
        // Different types of predecessors compose differently
        // This call eventually recurses through all predecessors
        // terminating at an RLS structure.
        let composedInputFunction = predecessor.compose(deliveryWrapper)
        
        var isComplete = false
            
        // Consumer composes the final push function here.
        composition = { value in
            guard !isComplete else { throw ReallyLazySequenceError.isComplete }
            if value == nil { isComplete = true }
            var result: ContinuationResult = .done(.canContinue)
            do {
                result = ContinuationResult.complete(try composedInputFunction(value))
            } catch {
                print(error)
            }
            return result
        }
    }
    
    public func process(_ value: T?) throws -> ContinuationResult { return try composition(value) }
}
