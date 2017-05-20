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

public protocol Consumable: Pushable {
    associatedtype ConsumableType
    typealias Delivery = (ConsumableType?) -> Void
    typealias ContinuableDelivery = (ConsumableType?) -> Continuation
    typealias PushFunction = (PushableType?) throws -> Void
    func consume(_ delivery: @escaping Delivery) -> Consumer<Self>
    func compose(_ delivery: @escaping ContinuableDelivery) -> PushFunction
}

public extension Consumable {
    func consume(_ delivery: @escaping (ConsumableType?) -> Void) -> Consumer<Self> {
        return Consumer(predecessor: self, delivery: delivery)
    }
}

public protocol ConsumerProtcol: Pushable {
    func push(_ value: PushableType?) throws -> Void
}

public protocol AsynchronousSequenceProtocol: Consumable {
    func map<T>( _ transform: @escaping (ConsumableType) -> T ) -> Map<Self, T>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, ConsumableType) -> T ) -> Reduce<Self, T>
    func filter(_ filter: @escaping (ConsumableType) -> Bool ) -> Filter<Self>
    func sort(_ comparison: @escaping (ConsumableType, ConsumableType) -> Bool ) -> Sort<Self>
}

public extension AsynchronousSequenceProtocol {
    func map<T>(_ transform: @escaping (ConsumableType) -> T ) -> Map<Self, T> {
        return Map(predecessor: self, transform: transform)
    }
    
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, ConsumableType) -> T) -> Reduce<Self, T> {
        return Reduce(predecessor: self, initialValue: initialValue, combine: combine)
    }
    
    func filter( _ filter: @escaping (ConsumableType) -> Bool) -> Filter<Self> {
        return Filter(predecessor: self, filter: filter )
    }
    
    func sort(_ comparison: @escaping (ConsumableType, ConsumableType) -> Bool) -> Sort<Self> {
        return Sort(predecessor: self, comparison: comparison)
    }
}

