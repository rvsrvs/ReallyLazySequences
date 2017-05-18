//
//  RealiyLazySequenceProtocols.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/17/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

public typealias Continuation = () -> Any?

public protocol Pushable {
    associatedtype PushableType
}

public protocol Observable: Pushable {
    associatedtype ObservableType
    typealias Delivery = (ObservableType?) -> Void
    typealias ContinuableDelivery = (ObservableType?) -> Continuation
    typealias PushFunction = (PushableType?) throws -> Void
    func observe(_ delivery: @escaping Delivery) -> Observed<Self>
    func compose(_ delivery: @escaping ContinuableDelivery) -> PushFunction
}

public extension Observable {
    func observe(_ delivery: @escaping (ObservableType?) -> Void) -> Observed<Self> {
        return Observed(predecessor: self, delivery: delivery)
    }
}

public protocol ObservedProtcol: Pushable {
    func push(_ value: PushableType?) throws -> Void
}

public protocol AsynchronousSequenceProtocol: Observable {
    func map<T>( _ transform: @escaping (ObservableType) -> T ) -> Map<Self, T>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, ObservableType) -> T ) -> Reduce<Self, T>
    func filter(_ filter: @escaping (ObservableType) -> Bool ) -> Filter<Self>
    func sort(_ comparison: @escaping (ObservableType, ObservableType) -> Bool ) -> Sort<Self>
}

public extension AsynchronousSequenceProtocol {
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
        return Sort(predecessor: self, comparison: comparison)
    }
}

