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
    func consume(_ delivery: @escaping (SequentialType?) -> Void) -> Consumer<Self> {
        return Consumer(predecessor: self, delivery: delivery)
    }
}

// Implement Sequencing
public extension ReallyLazySequenceProtocol {
    public func map<T>(_ transform: @escaping (SequentialType) -> T ) -> Map<Self, T> {
        return Map<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((SequentialType?) -> Continuation) in
            return { (input: SequentialType?) -> Continuation in
                guard let input = input else { return { delivery(nil) } }
                return { delivery(transform(input)) }
            }
        }
    }
    
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, SequentialType) -> T ) -> Reduce<Self, T> {
        return Reduce<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((SequentialType?) -> Continuation) in
            var partialValue = initialValue
            return { (input: SequentialType?) -> Continuation in
                guard let input = input else { partialValue = initialValue; return deliver(values: [partialValue], delivery: delivery) }
                return { partialValue = combine(partialValue, input); return nil }
            }
        }
    }
    
    func filter(_ filter: @escaping (SequentialType) -> Bool ) -> Filter<Self, SequentialType> {
        return Filter<Self, SequentialType>(predecessor: self) {
            (delivery: @escaping (SequentialType?) -> Continuation) -> ((SequentialType?) -> Continuation) in
            return { (input: SequentialType?) -> Continuation in
                if input == nil || filter(input!) { return { delivery(input) } }
                return { return nil }
            }
        }
    }
    
    func sort(_ comparison: @escaping (SequentialType, SequentialType) -> Bool ) -> Sort<Self, SequentialType> {
        return Sort<Self, SequentialType>(predecessor: self) {
            (delivery: @escaping (SequentialType?) -> Continuation) -> ((SequentialType?) -> Continuation) in
            var accumulator: [SequentialType] = []
            return { (input: SequentialType?) -> Continuation in
                guard let input = input else {
                    return deliver(values: accumulator.sorted(by: comparison), delivery: delivery)
                }
                return { accumulator.append(input); return nil }
            }
        }
    }
}

public extension ChainedSequence {
    public func compose(_ output: @escaping (SequentialType?) -> Continuation) -> ((PredecessorType.HeadType?) throws -> Void) {
        let composition = self.composer(output)
        return predecessor.compose(composition)
    }
}


