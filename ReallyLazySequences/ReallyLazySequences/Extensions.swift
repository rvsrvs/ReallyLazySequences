//
//  ReallyLazySequenceExtensions.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

// Recursively call delivery on the elements of values until each element's recursive call returns nil
fileprivate func deliver<T>(values:[T], delivery: @escaping (T?) -> Continuation, value: Continuation? = nil) -> Continuation {
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


// Implement Sequential
public extension ReallyLazySequenceProtocol {
    func consume(_ delivery: @escaping (OutputType?) -> Void) -> Consumer<Self> {
        return Consumer(predecessor: self, delivery: delivery)
    }
    func produce(_ input: @escaping (PushFunction) throws -> Void) -> Producer<Self> {
        return Producer<Self>(predecessor: self, input)
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
    
    func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<ReallyLazySequence<T>>) -> FlatMapSequence<Self, T> {
        return FlatMapSequence<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((OutputType?) -> Continuation) in
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { return { delivery(nil) } }
                let producer = transform(input)
                let task = producer.consume { (value: T?) -> Void in
                    guard let value = value else { return }
                    var nextDelivery: Continuation? = delivery(value)
                    while nextDelivery != nil { nextDelivery = nextDelivery!() as? Continuation }
                }
                task.start { (t:TaskProtocol) in
                    
                }
                // Need to process the Sequence from transform here
                return { delivery(nil) }
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
}

public extension ChainedSequence {
    public func compose(_ output: @escaping (OutputType?) -> Continuation) -> ((PredecessorType.InputType?) throws -> Void) {
        let composition = self.composer(output)
        return predecessor.compose(composition)
    }
}


