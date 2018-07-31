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
    func consume(_ delivery: @escaping (Self.OutputType?) -> Continuation) -> Consumer<Self> {
        return Consumer<Self>(predecessor: self, delivery:  delivery )
    }
}

// Implement Composition
public extension ReallyLazySequenceProtocol {
    //NB This only gets called when we are NOT a ChainedSequence, i.e. we are the root RLS in a chain
    // Hence the guard let below succeeds as a conversion to our output
    public func compose(_ output: @escaping OutputFunction) -> InputFunction {
        return { (value: InputType?) -> Void in
            guard let value = value as? OutputType? else { return }
            var nextDelivery: Continuation? = output(value)
            while nextDelivery != nil { nextDelivery = nextDelivery!() as? Continuation }
        }
    }
}

// ChainedSequences simply compose their composition with all successesors with their predecessor
// This recurses all the way back to the head sequence where it terminates because the head is NOT
// a ChainedSequence
public extension ChainedSequence {
    public func compose(_ output: @escaping OutputFunction) -> ((PredecessorType.InputType?) throws -> Void) {
        return predecessor.compose(self.composer(output))
    }
}

// Implement Sequencing
// Each of the methods below composes a function from 3 different elements
// 1. Its predecessors composed function
// 2. It's own associated function which takes the predecessors output type and operates on it to produce its own output type
// 3. a particular function which is specific to the action being taken
// Number 3 is what is being passed in to the initializer of the specific type in each case

func drive(_ continuation: Continuation) {
    var next = continuation(); while let current = next as? Continuation { next = current() }
}

public extension ReallyLazySequenceProtocol {
    // Map sequential values of one type to a value of the same or different type
    public func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T> {
        return Map<Self, T>(predecessor: self) { delivery in
            { input in input == nil ? { delivery(nil) } : { delivery(transform(input!)) } }
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
            var partialValue = initialValue(), nextPartialValue: T?
            return { input in
                guard let input = input else { drive(delivery(partialValue)); return { delivery(nil) } }
                partialValue = combine(nextPartialValue ?? partialValue, input); nextPartialValue = nil
                if until(partialValue, input) { drive(delivery(partialValue)); nextPartialValue = initialValue() }
                return ContinuationDone
            }
        }
    }

    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) -> T) -> Reduce<Self, T> {
        return collect(initialValue: initialValue, combine: combine, until: { $1 == nil })
    }

    // filter values that do not meet a specified condition
    func filter(_ filter: @escaping (OutputType) -> Bool ) -> Filter<Self, OutputType> {
        return Filter<Self, OutputType>(predecessor: self) { delivery in
            { input in (input == nil || filter(input!)) ? { delivery(input) } :  ContinuationDone }
        }
    }
    
    // create a sequence of values from a single value
    func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<T>) -> FlatMap<Self, T> {
        return FlatMap<Self, T>(predecessor: self) { delivery in
            { input in
                guard let input = input else { return { delivery(nil) } }
                try? transform(input)
                    .task { value in value != nil ? delivery(value) : ContinuationDone }
                    .start()
                return ContinuationDone
            }
        }
    }

    // Perform the rest of the push on another dispatch queue
    public func dispatch(_ queue: OperationQueue) -> Dispatch<Self, OutputType> {
        return Dispatch<Self, OutputType>(predecessor: self) { delivery in
            { input in queue.addOperation(BlockOperation { drive(delivery(input)) } ); return ContinuationDone }
        }
    }
}



