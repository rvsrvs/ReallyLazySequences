//
//  AsynchronousSequence.swift
//  frp
//
//  Created by Van Simmons on 4/7/17.
//  Copyright © 2017 Harvard University. All rights reserved.
//


/**
 ### Cases:
 1. Map (Single Value in/Single Value out)
 1. Reduce (Sequence in/Single Value out)
 1. Filter (Many value in/ Many value out
 1. Sort
 1. FlatMap (Sequence in/Many Sequences out)
 1. Skip
 1. Take (early termination)
 1. Batch (Subsequence in / Sequence(Collection?) out)
 
 ### Threads and Queues
 
 ### Multiplex/Demultiplex
 1. Many Sequences in/Tuple out
 1. Tuple In/ Many Sequences out
 */

enum AsynchronousSequenceError: Error {
    case mustHaveDelivery
    case isComplete
    
    var description: String {
        switch self {
        case .mustHaveDelivery:
            return "AsynchronousSequences must have a specified delivery mechanism before calling push()"
        case .isComplete:
            return "AsynchronousSequences has already completed.  Pushes not allowed"
        }
    }
}

protocol AsynchronousSequenceProtocol {
    associatedtype InputType
    associatedtype OutputType
    var push: (InputType?) throws -> Void { get }
    func compose(_ delivery: @escaping (OutputType?) -> Void) -> ((InputType?) -> Void)
    func observe(_ delivery: @escaping (OutputType) -> Void) -> ObservedAsynchronousSequence<Self, OutputType>
    func map<U>( _ transform: @escaping (OutputType) -> U ) -> MappedAsynchronousSequence<Self, OutputType, U>
    func reduce<U>(_ initialValue: U, _ combine: @escaping (U, OutputType) -> U ) -> ReducedAsynchronousSequence<Self, OutputType, U>
    func filter(_ filter: @escaping (OutputType) -> Bool ) -> FilteredAsynchronousSequence<Self>
    func sort(_ comparison: @escaping (OutputType, OutputType) -> Bool ) -> SortedAsynchronousSequence<Self>
}

extension AsynchronousSequenceProtocol {
    var push: (InputType?) throws -> Void { get { return { _ in throw AsynchronousSequenceError.mustHaveDelivery } } }
    
    func observe(_ delivery: @escaping (OutputType) -> Void) -> ObservedAsynchronousSequence<Self, OutputType> {
        return ObservedAsynchronousSequence<Self, OutputType>(predecessor: self, delivery: delivery)
    }
    
    func map<U>(
        _ transform: @escaping (OutputType) -> U
    ) -> MappedAsynchronousSequence<Self, OutputType, U> {
        return MappedAsynchronousSequence<Self, OutputType, U> (
            predecessor: self,
            transform: transform
        )
    }

    func reduce<U>(
        _ initialValue: U,
        _ combine: @escaping (U, OutputType) -> U
    ) -> ReducedAsynchronousSequence<Self, OutputType, U> {
        return ReducedAsynchronousSequence<Self, OutputType, U>(
            predecessor: self,
            initialValue: initialValue,
            combine: combine
        )
    }

    func filter(
        _ filter: @escaping (OutputType) -> Bool
        ) -> FilteredAsynchronousSequence<Self> {
        return FilteredAsynchronousSequence<Self>(
            predecessor: self,
            filter: filter
        )
    }

    func sort(
        _ comparison: @escaping (OutputType, OutputType) -> Bool
    ) -> SortedAsynchronousSequence<Self> {
        return SortedAsynchronousSequence<Self>(
            predecessor: self,
            comparison: comparison
        )
    }
}

struct ObservedAsynchronousSequence<Predecessor: AsynchronousSequenceProtocol, T>
    where Predecessor.OutputType == T {
    var push: (Predecessor.InputType?) throws -> Void
    init(predecessor:Predecessor, delivery: @escaping ((T) -> Void)) {
        var isComplete = false
        let localDelivery = { (value: T?) -> Void in
            guard let value = value else {
                isComplete = true
                return
            }
            delivery(value)
        }
        let composition = predecessor.compose(localDelivery)
        push = { (value:Predecessor.InputType?) throws -> Void in
            guard isComplete == false else { throw AsynchronousSequenceError.isComplete }
            composition(value)
        }
    }
}

struct AsynchronousSequence<T>: AsynchronousSequenceProtocol {
    typealias InputType = T
    typealias OutputType = T
    func compose(_ delivery: @escaping (T?) -> Void) -> ((T?) -> Void) { return delivery }
}

struct MappedAsynchronousSequence<Predecessor: AsynchronousSequenceProtocol, T, U>: AsynchronousSequenceProtocol
where Predecessor.OutputType == T {
    typealias InputType = Predecessor.InputType
    typealias OutputType = U
    
    var predecessor: Predecessor
    var transform: (T) -> U
    
    init(predecessor: Predecessor, transform: @escaping (T) -> U) {
        self.predecessor = predecessor
        self.transform = transform
    }
    
    func compose(_ delivery: @escaping (U?) -> Void) -> ((Predecessor.InputType?) -> Void) {
        let transform = self.transform
        let composition = { (input: T?) in
            guard let input = input else { delivery(nil);  return }
            delivery(transform(input))
        }
        return predecessor.compose(composition)
    }
}

struct ReducedAsynchronousSequence<Predecessor: AsynchronousSequenceProtocol, T, U>: AsynchronousSequenceProtocol
    where Predecessor.OutputType == T {
    typealias InputType = Predecessor.InputType
    typealias OutputType = U
    
    var predecessor: Predecessor
    var initialValue: U
    var combine: (U, T) -> U
    
    init(predecessor: Predecessor, initialValue: U, combine: @escaping (U, T) -> U) {
        self.predecessor = predecessor
        self.initialValue = initialValue
        self.combine = combine
    }
    
    func compose(_ delivery: @escaping (U?) -> Void) -> ((Predecessor.InputType?) -> Void) {
        let combine = self.combine
        var partialValue = self.initialValue
        let composition = { (input: T?) -> Void in
            guard let input = input else { delivery(partialValue); delivery(nil); return }
            partialValue = combine(partialValue, input)
        }
        return predecessor.compose(composition)
    }
}

struct FilteredAsynchronousSequence<Predecessor: AsynchronousSequenceProtocol>: AsynchronousSequenceProtocol {
    typealias InputType = Predecessor.InputType
    typealias OutputType = Predecessor.OutputType
    
    var predecessor: Predecessor
    var filter: (OutputType) -> Bool
    
    init(predecessor: Predecessor, filter: @escaping (OutputType) -> Bool) {
        self.predecessor = predecessor
        self.filter = filter
    }
    
    func compose(_ delivery: @escaping (OutputType?) -> Void) -> ((Predecessor.InputType?) -> Void) {
        let filter = self.filter
        let composition = { (input: OutputType?) -> Void in
            guard let input = input else { delivery(nil); return }
            if filter(input) { delivery(input) }
        }
        return predecessor.compose(composition)
    }
}

struct SortedAsynchronousSequence<Predecessor: AsynchronousSequenceProtocol>: AsynchronousSequenceProtocol {
    typealias InputType = Predecessor.InputType
    typealias OutputType = Predecessor.OutputType
    
    var predecessor: Predecessor
    var comparison: (OutputType, OutputType) -> Bool
    
    init(predecessor: Predecessor, comparison: @escaping (OutputType, OutputType) -> Bool) {
        self.predecessor = predecessor
        self.comparison = comparison
    }
    
    func compose(_ delivery: @escaping (OutputType?) -> Void) -> ((Predecessor.InputType?) -> Void) {
        let comparison = self.comparison
        var accumulator: [OutputType] = []
        let composition = { (input: OutputType?) -> Void in
            guard let input = input else {
                for value in accumulator.sorted(by: comparison) { delivery(value) }
                delivery(nil)
                return
            }
            accumulator.append(input)
        }
        return predecessor.compose(composition)
    }
}

//struct FlatMapAsynchronousSequence<Predecessor: AsynchronousSequenceProtocol, T>: AsynchronousSequenceProtocol {
//    typealias InputType = Predecessor.InputType
//    typealias OutputType = T
//    
//    var predecessor: Predecessor
//    var generator: (InputType) -> [T]
//    
//    init(predecessor: Predecessor, generator: @escaping (InputType) -> [T]) {
//        self.predecessor = predecessor
//        self.generator = generator
//    }
//    
//    func compose(_ delivery: @escaping (OutputType?) -> Void) -> ((Predecessor.InputType?) -> Void) {
//        let generator = self.generator
//        let composition = { (input: InputType?) -> Void in
//            guard let input = input else { delivery(nil); return }
//            for i in generator(input) { delivery(i) }
//        }
//        return predecessor.compose(composition)
//    }
//}











