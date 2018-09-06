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
    
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ConsumableMap<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ConsumableCompactMap<Self, T>
    func flatMap<T>(_ transform: @escaping (OutputType) throws -> Subsequence<OutputType, T>) -> ConsumableFlatMap<Self, T>

    // Consumable chaining
    func dispatch(_ queue: OperationQueue) -> ConsumableDispatch<Self, OutputType>
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ConsumableReduce<Self, T>

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

public struct Consumer<T> {
    public var description: String
    private var composition: (T?) throws -> ContinuationResult
    
    public init(delivery: @escaping (T?) throws -> ContinuationResult) {
        self.description = standardizeRLSDescription("Consumer<\(type(of:T.self))>")
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
    
    public func process(_ value: T?) throws -> ContinuationResult { return try composition(value) }
}
