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

protocol Pushable {
    associatedtype PushableType
    var push: (PushableType?) throws -> Void { get }
}

extension Pushable {
    var push: (PushableType?) throws -> Void { get { return { _ in throw AsynchronousSequenceError.mustHaveDelivery } } }
}

protocol Observable: Pushable {
    associatedtype ObservableType
    func observe(_ delivery: @escaping (ObservableType) -> Void) -> Observed<Self>
    func compose(_ delivery: @escaping (ObservableType?) -> Void) -> ((PushableType?) -> Void)
}

extension Observable {
    func observe(_ delivery: @escaping (ObservableType) -> Void) -> Observed<Self> {
        return Observed(predecessor: self, delivery: delivery)
    }
}

struct Observed<Predecessor: Observable>{
    var push: (Predecessor.PushableType?) throws -> Void
    init(predecessor:Predecessor, delivery: @escaping ((Predecessor.ObservableType) -> Void)) {
        var isComplete = false
        let localDelivery = { (value: Predecessor.ObservableType?) -> Void in
            guard let value = value else { isComplete = true; return }
            delivery(value)
        }
        let composition = predecessor.compose(localDelivery)
        push = { (value:Predecessor.PushableType?) throws -> Void in
            guard isComplete == false else { throw AsynchronousSequenceError.isComplete }
            composition(value)
        }
    }
}

protocol AsynchronousSequenceProtocol: Observable {
    func map<U>( _ transform: @escaping (ObservableType) -> U ) -> Map<Self, U>
    func reduce<U>(_ initialValue: U, _ combine: @escaping (U, ObservableType) -> U ) -> Reduce<Self, U>
    func filter(_ filter: @escaping (ObservableType) -> Bool ) -> Filter<Self>
    func sort(_ comparison: @escaping (ObservableType, ObservableType) -> Bool ) -> Sort<Self>
}

extension AsynchronousSequenceProtocol {
    func map<T>(_ transform: @escaping (ObservableType) -> T ) -> Map<Self, T> {
        return Map(predecessor: self, transform: transform)
    }

    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, ObservableType) -> T) -> Reduce<Self, T> {
        return Reduce(predecessor: self, initialValue: initialValue, combine: combine)
    }

    func filter( _ filter: @escaping (ObservableType) -> Bool) -> Filter<Self> {
        return Filter(predecessor: self, filter: filter )
    }

    func sort(_ comparison: @escaping (ObservableType, ObservableType) -> Bool) -> Sort<Self> {
        return Sort( predecessor: self, comparison: comparison)
    }
}

struct AsynchronousSequence<ObservableType>: AsynchronousSequenceProtocol {
    typealias PushableType = ObservableType
    func compose(_ delivery: @escaping (ObservableType?) -> Void) -> ((PushableType?) -> Void) {
        return delivery
    }
}

struct Map<Predecessor: AsynchronousSequenceProtocol, ObservableType>: AsynchronousSequenceProtocol {
    typealias PushableType = Predecessor.PushableType
    typealias Mapper = (Predecessor.ObservableType) -> ObservableType
    
    var predecessor: Predecessor
    var transform: Mapper
    
    init(predecessor: Predecessor, transform: @escaping Mapper) {
        self.predecessor = predecessor
        self.transform = transform
    }
    
    func compose(_ delivery: @escaping (ObservableType?) -> Void) -> ((Predecessor.PushableType?) -> Void) {
        let transform = self.transform
        let composition = { (input: Predecessor.ObservableType?) in
            guard let input = input else { delivery(nil);  return }
            delivery(transform(input))
        }
        return predecessor.compose(composition)
    }
}

struct Reduce<Predecessor: AsynchronousSequenceProtocol, ObservableType>: AsynchronousSequenceProtocol {
    typealias PushableType = Predecessor.PushableType
    typealias Combiner = (ObservableType, Predecessor.ObservableType) -> ObservableType
    
    var predecessor: Predecessor
    var initialValue: ObservableType
    var combine: Combiner
    
    init(predecessor: Predecessor, initialValue: ObservableType, combine: @escaping Combiner) {
        self.predecessor = predecessor
        self.initialValue = initialValue
        self.combine = combine
    }
    
    func compose(_ delivery: @escaping (ObservableType?) -> Void) -> ((Predecessor.PushableType?) -> Void) {
        let combine = self.combine
        var partialValue = self.initialValue
        let composition = { (input: Predecessor.ObservableType?) -> Void in
            guard let input = input else { delivery(partialValue); delivery(nil); return }
            partialValue = combine(partialValue, input)
        }
        return predecessor.compose(composition)
    }
}

struct Filter<Predecessor: AsynchronousSequenceProtocol>: AsynchronousSequenceProtocol {
    typealias PushableType = Predecessor.PushableType
    typealias ObservableType = Predecessor.ObservableType
    typealias Filterer = (Predecessor.ObservableType) -> Bool
    
    var predecessor: Predecessor
    var filter: Filterer
    
    init(predecessor: Predecessor, filter: @escaping Filterer) {
        self.predecessor = predecessor
        self.filter = filter
    }
    
    func compose(_ delivery: @escaping (ObservableType?) -> Void) -> ((Predecessor.PushableType?) -> Void) {
        let filter = self.filter
        let composition = { (input: ObservableType?) -> Void in
            guard let input = input else { delivery(nil); return }
            if filter(input) { delivery(input) }
        }
        return predecessor.compose(composition)
    }
}

struct Sort<Predecessor: AsynchronousSequenceProtocol>: AsynchronousSequenceProtocol {
    typealias PushableType = Predecessor.PushableType
    typealias ObservableType = Predecessor.ObservableType
    typealias Comparator = (Predecessor.ObservableType, Predecessor.ObservableType) -> Bool
    
    var predecessor: Predecessor
    var comparison: Comparator
    
    init(predecessor: Predecessor, comparison: @escaping Comparator) {
        self.predecessor = predecessor
        self.comparison = comparison
    }
    
    func compose(_ delivery: @escaping (ObservableType?) -> Void) -> ((Predecessor.PushableType?) -> Void) {
        let comparison = self.comparison
        var accumulator: [ObservableType] = []
        let composition = { (input: ObservableType?) -> Void in
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
//    typealias PushableType = Predecessor.PushableType
//    typealias ObservableType = T
//
//    var predecessor: Predecessor
//    var generator: (PushableType) -> [T]
//
//    init(predecessor: Predecessor, generator: @escaping (PushableType) -> [T]) {
//        self.predecessor = predecessor
//        self.generator = generator
//    }
//    
//    func compose(_ delivery: @escaping (ObservableType?) -> Void) -> ((Predecessor.PushableType?) -> Void) {
//        let generator = self.generator
//        let composition = { (input: PushableType?) -> Void in
//            guard let input = input else { delivery(nil); return }
//            for i in generator(input) { delivery(i) }
//        }
//        return predecessor.compose(composition)
//    }
//}











