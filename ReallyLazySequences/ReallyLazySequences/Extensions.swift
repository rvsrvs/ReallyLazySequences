//
//  ReallyLazySequenceExtensions.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

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
                guard let input = input else {
                    let finalValue = [partialValue]; partialValue = initialValue
                    return deliver(values: finalValue, delivery: delivery)
                }
                return { partialValue = combine(partialValue, input); return nil }
            }
        }
    }
    
    func filter(_ filter: @escaping (OutputType) -> Bool ) -> Filter<Self, OutputType> {
        return Filter<Self, OutputType>(predecessor: self) {
            (delivery: @escaping (OutputType?) -> Continuation) -> ((OutputType?) -> Continuation) in
            return { (input: OutputType?) -> Continuation in
                if input == nil || filter(input!) { return { delivery(input) } }
                return { return nil }
            }
        }
    }
    
    func sort(_ comparison: @escaping (OutputType, OutputType) -> Bool ) -> Sort<Self, OutputType> {
        return Sort<Self, OutputType>(predecessor: self) {
            (delivery: @escaping (OutputType?) -> Continuation) -> ((OutputType?) -> Continuation) in
            var accumulator: [OutputType] = []
            return { (input: OutputType?) -> Continuation in
                guard let input = input else {
                    let sorted = accumulator.sorted(by: comparison); accumulator = []
                    return deliver(values: sorted, delivery: delivery)
                }
                return { accumulator.append(input); return nil }
            }
        }
    }
    
    func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<T>) -> FlatMapSequence<Self, T> {
        return FlatMapSequence<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((OutputType?) -> Continuation) in
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { return { delivery(nil) } }
                let producer = transform(input)
                let task = producer.consume { (value: T?) -> Continuation in
                    guard let value = value else { return { nil } }
                    var nextDelivery: Continuation? = delivery(value)
                    while nextDelivery != nil { nextDelivery = nextDelivery!() as? Continuation }
                    return { nil }
                }
                return {
                    try? task.push(nil);
                    return nil
                }
            }
        }
    }
}



