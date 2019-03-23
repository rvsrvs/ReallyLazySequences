//
//  Consumer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//

/*
 Copyright 2019, Ronald V. Simmons
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public protocol ConsumableSequenceProtocol: SequenceProtocol {
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

public protocol ChainedConsumableSequenceProtocol: ConsumableSequenceProtocol {
    associatedtype PredecessorType: ConsumableSequenceProtocol
    typealias PredecessorContinuableOutputDelivery = (PredecessorType.OutputType?) -> ContinuationResult
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorContinuableOutputDelivery
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

public enum ConsumerError: Error {
    case isComplete
}

public struct Consumer<T> {
    public var description: String
    private var composition: (T?) throws -> ContinuationResult
    
    public init(delivery: @escaping (T?) throws -> ContinuationResult, description: String = "") {
        self.description = Utilities.standardizeDescription(description)
        var isComplete = false
        composition = { value in
            guard !isComplete else { throw ConsumerError.isComplete }
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
