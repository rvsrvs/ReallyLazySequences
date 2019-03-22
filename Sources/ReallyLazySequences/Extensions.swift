//
//  ReallyLazySequenceExtensions.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//

/*
 Copyright 2019, Ronald V. Simmons
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

// Implement Consume
public extension ConsumableSequenceProtocol {
    func consume(_ delivery: @escaping (Self.OutputType?) -> ContinuationTermination) -> Consumer<Self.InputType> {
        let deliveryWrapper = {  (output: Self.OutputType?) -> ContinuationResult in
            let result = delivery(output)
            return .done(result)
        }
        let output: Self.OutputType?
        let consumeType = "\(type(of: output))"
            .replacingOccurrences(of: "Optional<", with: "")
            .replacingOccurrences(of: ">", with: "")
        let desc = self.description + " >> consume<\(consumeType)>"
        return Consumer(delivery: compose(deliveryWrapper)!, description: desc)
    }

    func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery? {
        return { (value: InputType?) -> ContinuationResult in
            guard let value = value as? OutputType? else { return .done(.terminate) }
            return .more({ delivery(value) })
        }
    }
}

public extension ChainedConsumableSequenceProtocol {
    func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery?  {
        return predecessor.compose(composer(delivery)) as? (Self.InputType?) throws -> ContinuationResult
    }
}

public extension ConsumableSequenceProtocol {
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ConsumableMap<Self, T> {
        return ConsumableMap<Self, T>(predecessor: self) { delivery in
            Composers.mapComposer(delivery: delivery, transform: transform)
        }
    }
    
    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ConsumableCompactMap<Self, T> {
        return ConsumableCompactMap<Self, T>(predecessor: self) { delivery in
            return Composers.compactMapComposer(delivery: delivery, transform: transform)
        }
    }

    func flatMap<T>(_ transform: @escaping (OutputType) throws -> Subsequence<OutputType, T>) -> ConsumableFlatMap<Self, T> {
        return ConsumableFlatMap<Self, T>(predecessor: self) { delivery in
            Composers.flatMapComposer(delivery: delivery, transform: transform)
        }
    }
    
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ConsumableReduce<Self, T> {
        return ConsumableReduce<Self, T>(predecessor: self) { delivery in
            return Composers.statefulCompactMapComposer(
                delivery: delivery,
                initialState: initialValue(),
                updateState: { (state: T, input: OutputType?) throws -> T in
                    guard let input = input else { return state }
                    return try combine(state, input)
                },
                transform: { (state: T, input: OutputType?) -> T? in
                    guard until(state, input) else { return nil }
                    return state
                }
            )
        }
    }
    
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ConsumableReduce<Self, T> {
        return collect(initialValue: initialValue, combine: combine, until: { $1 == nil })
    }

    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ConsumableFilter<Self, OutputType> {
        return ConsumableFilter<Self, OutputType>(predecessor: self) { delivery in
            let transform = { (value: OutputType) throws -> OutputType? in try filter(value) ? value : nil }
            return Composers.compactMapComposer(delivery: delivery, transform: transform)
        }
    }
    
    func dispatch(_ queue: OperationQueue) -> ConsumableDispatch<Self, OutputType> {
        return ConsumableDispatch<Self, OutputType>(predecessor: self) { delivery in
            Composers.dispatchComposer(delivery: delivery, queue: queue)
        }
    }
}

extension ChainedListenableSequenceProtocol {
    public func proxy() -> ListenerHandle<ListenableType> {
        return predecessor.proxy()
    }
    
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery?  {
        return predecessor.compose(composer(delivery)) as? ContinuableInputDelivery
    }

    public func listen(_ delivery: @escaping (OutputType?) -> ContinuationTermination) -> ListenerHandle<Self.ListenableType> {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in
            return .done(delivery(value))
        }
        let _ = predecessor.compose(composer(deliveryWrapper))
        return predecessor.proxy()
    }
}

public extension ListenableSequenceProtocol {
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ListenableMap<Self, T> {
        return ListenableMap<Self, T>(predecessor: self) { delivery in
            Composers.mapComposer(delivery: delivery, transform: transform)
        }
    }

    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ListenableCompactMap<Self, T> {
        return ListenableCompactMap<Self, T>(predecessor: self) { delivery in
            return Composers.compactMapComposer(delivery: delivery, transform: transform)
        }
    }

    func flatMap<T>(_ transform: @escaping (OutputType) throws -> Subsequence<OutputType, T>) -> ListenableFlatMap<Self, T> {
        return ListenableFlatMap<Self, T>(predecessor: self) { delivery in
            Composers.flatMapComposer(delivery: delivery, transform: transform)
        }
    }
    
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ListenableReduce<Self, T> {
        return ListenableReduce<Self, T>(predecessor: self) { delivery in
            return Composers.statefulCompactMapComposer(
                delivery: delivery,
                initialState: initialValue(),
                updateState: { (state: T, input: OutputType?) throws -> T in
                    guard let input = input else { return state }
                    return try combine(state, input)
                },
                transform: { (state: T, input: OutputType?) -> T? in
                    guard until(state, input) else { return nil }
                    return state
                }
            )
        }
    }
    
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ListenableReduce<Self, T> {
        return collect(initialValue: initialValue, combine: combine, until: { $1 == nil })
    }
    
    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ListenableFilter<Self, OutputType> {
        return ListenableFilter<Self, OutputType>(predecessor: self) { delivery in
            let transform = { (value: OutputType) throws -> OutputType? in try filter(value) ? value : nil }
            return Composers.compactMapComposer(delivery: delivery, transform: transform)
        }
    }

    func dispatch(_ queue: OperationQueue) -> ListenableDispatch<Self, OutputType> {
        return ListenableDispatch<Self, OutputType>(predecessor: self) { delivery in
            Composers.dispatchComposer(delivery: delivery, queue: queue)
        }
    }
}
