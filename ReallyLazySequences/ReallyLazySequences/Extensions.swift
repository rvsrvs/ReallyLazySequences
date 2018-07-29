//
//  ReallyLazySequenceExtensions.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//
import Foundation

// Recursively call delivery on the elements of values until each element's recursive call returns nil
func deliver<T>(values:[T], delivery: @escaping (T?) -> Continuation, value: Continuation? = nil) -> Continuation {
    if let value = value {
        return { deliver(values: values, delivery: delivery, value: value() as? Continuation ) }
    } else if values.count > 0 {
        let value = delivery(values.first!)
        let values = Array(values.dropFirst())
        return { deliver(values: values, delivery: delivery, value: value) }
    } else {
        return { delivery(nil) }
    }
}

// Implement Consume
public extension ReallyLazySequenceProtocol {
    func consume(_ delivery: @escaping (Self.OutputType?) -> Continuation) -> Consumer<Self> {
        return Consumer<Self>(predecessor: self, delivery:  delivery )
    }
}

// Implement Composition
public extension ReallyLazySequenceProtocol {
    public func compose(_ output: @escaping (Self.OutputType?) -> Continuation) -> ((Self.InputType?) throws -> Void) {
        return { (value: InputType?) -> Void in
            guard let value = value as? OutputType? else { return }
            var nextDelivery: Continuation? = output(value)
            while nextDelivery != nil { nextDelivery = nextDelivery!() as? Continuation }
        }
    }
}

public extension ChainedSequence {
    public func compose(_ output: @escaping (OutputType?) -> Continuation) -> ((PredecessorType.InputType?) throws -> Void) {
        return predecessor.compose(self.composer(output))
    }
}

// Implement Sequencing
public extension ReallyLazySequenceProtocol {
    public func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T> {
        return Map<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((OutputType?) -> Continuation) in
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { return { delivery(nil) } }
                return { delivery(transform(input)) }
            }
        }
    }
    
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) -> T ) -> Reduce<Self, T> {
        return Reduce<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((OutputType?) -> Continuation) in
            var partialValue = initialValue
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { return { delivery(partialValue) } }
                partialValue = combine(partialValue, input)
                return ContinuationDone
            }
        }
    }
    
    func filter(_ filter: @escaping (OutputType) -> Bool ) -> Filter<Self, OutputType> {
        return Filter<Self, OutputType>(predecessor: self) { (delivery: @escaping (OutputType?) -> Continuation) -> ((OutputType?) -> Continuation) in
            return { (input: OutputType?) -> Continuation in
                if input == nil || filter(input!) { return { delivery(input) } }
                return ContinuationDone
            }
        }
    }
    
    // sort holds values locally and then delivers them sequentially downstream when nil is received
    func sort(_ comparison: @escaping (OutputType, OutputType) -> Bool ) -> Sort<Self, OutputType> {
        return Sort<Self, OutputType>(predecessor: self) { (delivery: @escaping (OutputType?) -> Continuation) -> ((OutputType?) -> Continuation) in
            var accumulator: [OutputType] = []
            return { (input: OutputType?) -> Continuation in
                guard let input = input else {
                    let sorted = accumulator.sorted(by: comparison); accumulator = []
                    return deliver(values: sorted, delivery: delivery)
                }
                accumulator.append(input)
                return ContinuationDone
            }
        }
    }
    
    func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<T>) -> FlatMap<Self, T> {
        return FlatMap<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((OutputType?) -> Continuation) in
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { return { delivery(nil) } }
                let producer = transform(input)
                let task = producer.consume { (value: T?) -> Continuation in
                    guard let value = value else { return ContinuationDone }
                    return delivery(value)
                }
                return { try? task.push(nil); return nil }
            }
        }
    }

    public func dispatch(_ queue: OperationQueue) -> Dispatch<Self, OutputType> {
        return Dispatch<Self, OutputType>(predecessor: self) { (delivery: @escaping (OutputType?) -> Continuation) -> ((OutputType?) -> Continuation) in
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
    
    public func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) -> T,
        until: @escaping (T) -> Bool
    ) -> Collect<Self, T> {
        return Collect<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((OutputType?) -> Continuation) in
            var nextPartialValue: T?
            var partialValue = initialValue()
            return { (input: OutputType?) -> Continuation in
                if let newPartialValue = nextPartialValue { partialValue = newPartialValue }
                guard let input = input else { return deliver(values: [partialValue], delivery: delivery) }
                partialValue = combine(partialValue, input)
                if until(partialValue) {
                    nextPartialValue = initialValue()
                    return { delivery(partialValue) }
                }
                nextPartialValue = nil
                return ContinuationDone
            }
        }
    }
}



