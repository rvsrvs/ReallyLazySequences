//
//  ReallyLazySequenceExtensions.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//
import Foundation

// Implement Consume
public extension ConsumableProtocol {
    func consume(_ delivery: @escaping (Self.OutputType?) -> ContinuationTermination) -> Consumer<Self.InputType> {
        let deliveryWrapper = {  (output: Self.OutputType?) -> ContinuationResult in
            let result = delivery(output)
            return .done(result)
        }
        return compose(deliveryWrapper)!
    }
}

// Implement Composition
public extension ReallyLazySequenceProtocol {
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> Consumer<InputType>? {
        return Consumer<InputType> { (value: InputType?) -> ContinuationResult in
            guard let value = value as? OutputType? else { return .done(.terminate) }
            return .more({ delivery(value) })
        }
    }
}

public extension ChainedConsumableProtocol {
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> Consumer<InputType>?  {
        return predecessor.compose(composer(delivery)) as! Consumer<InputType>?
    }
}

// Implement Sequencing
// Each of the methods below composes a function from 3 different elements
// 1. Its predecessors composed function
// 2. It's own associated function which takes the predecessors output type and operates on it to produce its own output type
// 3. a particular function which is specific to the action being taken
// Number 3 is what is being passed in to the initializer of the specific types returned below

public extension ConsumableProtocol {
    public func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ConsumableMap<Self, T> {
        return ConsumableMap<Self, T>(predecessor: self) { delivery in
            Composers.mapComposer(delivery: delivery, transform: transform)
        }
    }
    
    public func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ConsumableCompactMap<Self, T> {
        return ConsumableCompactMap<Self, T>(predecessor: self) { delivery in
            Composers.compactMapComposer(delivery: delivery, transform: transform)
        }
    }

    public func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ConsumableReduce<Self, T> {
        return ConsumableReduce<Self, T>(predecessor: self) { delivery in
            Composers.collectComposer(delivery: delivery, initialValue: initialValue, combine: combine, until: until)
        }
    }
    
    func flatMap<T, U>(queue: OperationQueue?, _ transform: @escaping (OutputType) throws -> U) -> ConsumableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T {
            return ConsumableFlatMap<Self, T>(predecessor: self) { delivery in
                Composers.flatMapComposer(delivery: delivery, queue: queue, transform: transform)
            }
    }

    func flatMap<T, U>(_ transform: @escaping (OutputType) throws -> U) -> ConsumableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T {
        return flatMap(queue: nil, transform)
    }
    
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ConsumableReduce<Self, T> {
        return collect(initialValue: initialValue, combine: combine, until: { $1 == nil })
    }

    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ConsumableFilter<Self, OutputType> {
        return ConsumableFilter<Self, OutputType>(predecessor: self) { delivery in
            Composers.filterComposer(delivery: delivery, filter: filter)
        }
    }
    
    public func dispatch(_ queue: OperationQueue) -> ConsumableDispatch<Self, OutputType> {
        return ConsumableDispatch<Self, OutputType>(predecessor: self) { delivery in
            Composers.dispatchComposer(delivery: delivery, queue: queue)
        }
    }
}

extension ChainedListenerProtocol {
    public func proxy() -> ListenerHandle<ListenableType> {
        return predecessor.proxy()
    }
    
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> Consumer<InputType>?  {
        return predecessor.compose(composer(delivery)) as? Consumer<Self.InputType>
    }

    public func listen(_ delivery: @escaping (OutputType?) -> ContinuationTermination) -> ListenerHandle<Self.ListenableType> {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in
            return .done(delivery(value))
        }
        let _ = predecessor.compose(composer(deliveryWrapper))
        return predecessor.proxy()
    }
}

public extension ListenerProtocol {
    public func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ListenableMap<Self, T> {
        return ListenableMap<Self, T>(predecessor: self) { delivery in
            Composers.mapComposer(delivery: delivery, transform: transform)
        }
    }

    public func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ListenableCompactMap<Self, T> {
        return ListenableCompactMap<Self, T>(predecessor: self) { delivery in
            Composers.compactMapComposer(delivery: delivery, transform: transform)
        }
    }

    public func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ListenableReduce<Self, T> {
        return ListenableReduce<Self, T>(predecessor: self) { delivery in
            Composers.collectComposer(delivery: delivery, initialValue: initialValue, combine: combine, until: until)
        }
    }
    
    func flatMap<T, U>(queue: OperationQueue?, _ transform: @escaping (OutputType) throws -> U) -> ListenableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T {
            return ListenableFlatMap<Self, T>(predecessor: self) { delivery in
                Composers.flatMapComposer(delivery: delivery, queue: queue, transform: transform)
            }
    }
    
    func flatMap<T, U>(_ transform: @escaping (OutputType) throws -> U) -> ListenableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T {
            return flatMap(queue: nil, transform)
    }
    
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ListenableReduce<Self, T> {
        return collect(initialValue: initialValue, combine: combine, until: { $1 == nil })
    }
    
    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ListenableFilter<Self, OutputType> {
        return ListenableFilter<Self, OutputType>(predecessor: self) { delivery in
            Composers.filterComposer(delivery: delivery, filter: filter)
        }
    }
    
    public func dispatch(_ queue: OperationQueue) -> ListenableDispatch<Self, OutputType> {
        return ListenableDispatch<Self, OutputType>(predecessor: self) { delivery in
            Composers.dispatchComposer(delivery: delivery, queue: queue)
        }
    }
}



