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

fileprivate let nilContinutation: Continuation = { nil }

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

public struct Observed<Predecessor: Observable>: ObservedProtcol{
    public typealias PushableType = Predecessor.PushableType

    private let _push: (PushableType?) throws -> Void
    
    init(predecessor:Predecessor, delivery: @escaping ((Predecessor.ObservableType?) -> Void)) {
        var isComplete = false
        let deliveryWrapper = { (value: Predecessor.ObservableType?) -> Continuation in
            if value == nil { isComplete = true }
            return { delivery(value); return nil }
        }
        let composition = predecessor.compose(deliveryWrapper)
        _push = { (value:Predecessor.PushableType?) throws -> Void in
            guard !isComplete else { throw AsynchronousSequenceError.isComplete }
            try composition(value)
        }
    }
    
    public func push(_ value: PushableType?) throws -> Void { try _push(value) }
}

public struct AsynchronousSequence<ObservableType>: AsynchronousSequenceProtocol {
    public typealias PushableType = ObservableType
    public func compose(_ delivery: @escaping (ObservableType?) -> Continuation ) -> ((PushableType?) throws -> Void) {
        let dispatcher = Dispatcher()
        return  { value in try dispatcher.dispatch { delivery(value) } }
   }
}

public struct Map<Predecessor: AsynchronousSequenceProtocol, ObservableType>: AsynchronousSequenceProtocol {
    public typealias PushableType = Predecessor.PushableType
    typealias Mapper = (Predecessor.ObservableType) -> ObservableType
    
    var predecessor: Predecessor
    var transform: Mapper
    
    init(predecessor: Predecessor, transform: @escaping Mapper) {
        self.predecessor = predecessor
        self.transform = transform
    }
    
    public func compose(_ delivery: @escaping (ObservableType?) -> Continuation) -> ((Predecessor.PushableType?) throws -> Void) {
        let transform = self.transform
        let composition = { (input: Predecessor.ObservableType?) -> Continuation in
            guard let input = input else { return { delivery(nil) } }
            return { delivery(transform(input)) }
        }
        return predecessor.compose(composition)
    }
}

public struct Reduce<Predecessor: AsynchronousSequenceProtocol, ObservableType>: AsynchronousSequenceProtocol {
    public typealias PushableType = Predecessor.PushableType
    typealias Combiner = (ObservableType, Predecessor.ObservableType) -> ObservableType
    
    var predecessor: Predecessor
    var initialValue: ObservableType
    var combine: Combiner
    
    init(predecessor: Predecessor, initialValue: ObservableType, combine: @escaping Combiner) {
        self.predecessor = predecessor
        self.initialValue = initialValue
        self.combine = combine
    }
    
    public func compose(_ delivery: @escaping (ObservableType?) -> Continuation) -> ((Predecessor.PushableType?) throws -> Void) {
        let combine = self.combine
        var partialValue = self.initialValue
        let composition = { (input: Predecessor.ObservableType?) -> Continuation in
            guard let input = input else { return deliver(values: [partialValue], delivery: delivery) }
            return { partialValue = combine(partialValue, input); return nil }
        }
        return predecessor.compose(composition)
    }
}

public struct Filter<Predecessor: AsynchronousSequenceProtocol>: AsynchronousSequenceProtocol {
    public typealias PushableType = Predecessor.PushableType
    public typealias ObservableType = Predecessor.ObservableType
    typealias Filterer = (Predecessor.ObservableType) -> Bool
    
    var predecessor: Predecessor
    var filter: Filterer
    
    init(predecessor: Predecessor, filter: @escaping Filterer) {
        self.predecessor = predecessor
        self.filter = filter
    }
    
    public func compose(_ delivery: @escaping (ObservableType?) -> Continuation) -> ((Predecessor.PushableType?) throws -> Void) {
        let filter = self.filter
        let composition = { (input: ObservableType?) -> Continuation in
            if input == nil || filter(input!) { return { delivery(input) } }
            return nilContinutation
        }
        return predecessor.compose(composition)
    }
}

public struct Sort<Predecessor: AsynchronousSequenceProtocol>: AsynchronousSequenceProtocol {
    public typealias PushableType = Predecessor.PushableType
    public typealias ObservableType = Predecessor.ObservableType
    typealias Comparator = (Predecessor.ObservableType, Predecessor.ObservableType) -> Bool
    
    var predecessor: Predecessor
    var comparison: Comparator
    
    init(predecessor: Predecessor, comparison: @escaping Comparator) {
        self.predecessor = predecessor
        self.comparison = comparison
    }
    
    public func compose(_ delivery: @escaping (ObservableType?) -> Continuation) -> ((Predecessor.PushableType?) throws -> Void) {
        let comparison = self.comparison
        var accumulator: [ObservableType] = []
        let composition = { (input: ObservableType?) -> Continuation in
            guard let input = input else {
                return deliver(values: accumulator.sorted(by: comparison), delivery: delivery)
            }
            return { accumulator.append(input); return nil }
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











