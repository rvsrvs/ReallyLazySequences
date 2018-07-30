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

public extension ChainedSequence {
    public func compose(_ output: @escaping OutputFunction) -> ((PredecessorType.InputType?) throws -> Void) {
        return predecessor.compose(self.composer(output))
    }
}

// Implement Sequencing
public extension ReallyLazySequenceProtocol {
    public func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T> {
        return Map<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> (OutputFunction) in
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { return { delivery(nil) } }
                return { delivery(transform(input)) }
            }
        }
    }
    
    public func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> Reduce<Self, T> {
        return Reduce<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> (OutputFunction) in
            var nextPartialValue: T?
            var partialValue = initialValue()
            return { (input: OutputType?) -> Continuation in
                if let newPartialValue = nextPartialValue { partialValue = newPartialValue }
                guard let input = input else {
                    return {
                        var next = delivery(partialValue)()
                        while let current = next as? Continuation { next = current() }
                        next = delivery(nil)()
                        while let current = next as? Continuation { next = current() }
                        return ContinuationDone
                    }
                }
                partialValue = combine(partialValue, input)
                if until(partialValue, input) {
                    nextPartialValue = initialValue()
                    return { delivery(partialValue) }
                }
                nextPartialValue = nil
                return ContinuationDone
            }
        }
    }

    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) -> T) -> Reduce<Self, T> {
        return collect(initialValue: initialValue, combine: combine, until: { $1 == nil })
    }

    func filter(_ filter: @escaping (OutputType) -> Bool ) -> Filter<Self, OutputType> {
        return Filter<Self, OutputType>(predecessor: self) { (delivery: @escaping OutputFunction) -> (OutputFunction) in
            return { (input: OutputType?) -> Continuation in
                if input == nil || filter(input!) { return { delivery(input) } }
                return ContinuationDone
            }
        }
    }
    
    func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<T>) -> FlatMap<Self, T> {
        return FlatMap<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> (OutputFunction) in
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { return { delivery(nil) } }
                let producer = transform(input)
                let task = producer.task { (value: T?) -> Continuation in
                    guard let value = value else { return ContinuationDone }
                    return delivery(value)
                }
                return { try? task.start(); return nil }
            }
        }
    }

    public func dispatch(_ queue: OperationQueue) -> Dispatch<Self, OutputType> {
        return Dispatch<Self, OutputType>(predecessor: self) { (delivery: @escaping OutputFunction) -> (OutputFunction) in
            return { (input: OutputType?) -> Continuation in
                let op = BlockOperation {
                    var next = delivery(input)()
                    while let current = next as? Continuation { next = current() }
                }
                queue.addOperation(op)
                return ContinuationDone
            }
        }
    }
}



