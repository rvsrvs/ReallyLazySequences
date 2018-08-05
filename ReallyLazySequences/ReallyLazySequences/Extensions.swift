//
//  ReallyLazySequenceExtensions.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//
import Foundation

// Implement Consume
public extension ReallyLazySequenceProtocol {
    func consume(_ delivery: @escaping (Self.OutputType?) -> Void) -> Consumer<Self> {
        return Consumer<Self>(predecessor: self, delivery:  delivery )
    }
}

// Implement Composition
public extension ReallyLazySequenceProtocol {
    //NB This only gets called when we are NOT a ChainedSequence, i.e. we are the root RLS in a chain
    // Hence the guard let below succeeds as a conversion to our output since on the actual RLS struct
    // InputType == OutputType
    public func compose(_ output: @escaping OutputFunction) -> InputFunction {
        return { guard let value = $0 as? OutputType? else { return }; drive(output(value)) }
    }
}

// ChainedSequences simply compose their composition with all successesors with their predecessor
// This recurses all the way back to the head sequence where it terminates because the head is NOT
// a ChainedSequence
public extension ChainedSequence {
    public func compose(_ output: @escaping OutputFunction) -> ((PredecessorType.InputType?) throws -> Void) {
        return predecessor.compose(composer(output))
    }
}

// Implement Sequencing
// Each of the methods below composes a function from 3 different elements
// 1. Its predecessors composed function
// 2. It's own associated function which takes the predecessors output type and operates on it to produce its own output type
// 3. a particular function which is specific to the action being taken
// Number 3 is what is being passed in to the initializer of the specific type in each case

public extension ReallyLazySequenceProtocol {
    // Map sequential values of one type to a value of the same or different type
    public func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T> {
        return Map<Self, T>(predecessor: self) { delivery in
            return { input in input == nil ? { delivery(nil) } : { delivery(transform(input!)) } }
        }
    }
    
    // When the OutputType of the sequence is an optional, remove nils from the sequence, and transform
    // the non-optional type
    public func compactMap<T, U>(_ transform: @escaping (T) -> U ) -> CompactMap<Self, U> where OutputType == T? {
        return CompactMap<Self, U>(predecessor: self) { delivery in
            return { optionalOptionalInput in
                guard let optionalInput = optionalOptionalInput else { return delivery(nil) }
                guard let input = optionalInput else { return ContinuationDone }
                return { delivery(transform(input)) }
            }
        }
    }

    // A generalized form of reduce which allows collection of values until a condition is reached
    // Collected values are then forwarded as the collecting type to the successor when the until condition is met
    // this function allows the initial value to be reset before receiving input of nil
    public func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> Reduce<Self, T> {
        return Reduce<Self, T>(predecessor: self) { delivery in
            var partialValue = initialValue()
            var setNextPartialValue: Continuation?
            return { input in
                _ = setNextPartialValue?(); setNextPartialValue = nil
                guard let input = input else { drive(delivery(partialValue)); return { delivery(nil) } }
                partialValue = combine(partialValue, input)
                if until(partialValue, input) {
                    setNextPartialValue = { partialValue = initialValue(); return nil }
                    return { delivery(partialValue) }
                }
                return ContinuationDone
            }
        }
    }
    
    // create a sequence of values from a single value
    func flatMap<T>(queue: OperationQueue?, _ transform: @escaping (OutputType) -> Producer<T>) -> FlatMap<Self, T> {
        return FlatMap<Self, T>(predecessor: self) { delivery in
            return { input in
                guard let input = input else { return { delivery(nil) } }
                let task = transform(input)
                    .task { value in
                        guard let value = value else { return }
                        drive(delivery(value))
                    }
                if let queue = queue {
                    queue.addOperation { try? task.start() }
                } else {
                    try? task.start()
                }
                return ContinuationDone
            }
        }
    }

    // create a sequence of values from a single value
    func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<T>) -> FlatMap<Self, T> {
        return flatMap(queue: nil, transform)
    }
    
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) -> T) -> Reduce<Self, T> {
        return collect(initialValue: initialValue, combine: combine, until: { $1 == nil })
    }

    // filter values that do not meet a specified condition
    func filter(_ filter: @escaping (OutputType) -> Bool ) -> Filter<Self, OutputType> {
        return Filter<Self, OutputType>(predecessor: self) { delivery in
            return { input in (input == nil || filter(input!)) ? { delivery(input) } :  ContinuationDone }
        }
    }
    
    // Perform the rest of the push on another dispatch queue
    public func dispatch(_ queue: OperationQueue) -> Dispatch<Self, OutputType> {
        return Dispatch<Self, OutputType>(predecessor: self) { delivery in
            return { input in queue.addOperation(BlockOperation { drive(delivery(input)) } ); return ContinuationDone }
        }
    }
}



