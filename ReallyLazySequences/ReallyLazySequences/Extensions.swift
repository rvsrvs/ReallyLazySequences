//
//  ReallyLazySequenceExtensions.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/24/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//
import Foundation

// Implement Consume
public extension ReallyLazySequenceProtocol {
    func consume(_ delivery: @escaping (Self.OutputType?) -> Void) -> Consumer<Self> {
        return Consumer<Self>(predecessor: self, delivery:  delivery )
    }
    
    public func listen(_ delivery: @escaping (OutputType?) -> Void) {  }
}

// Implement Composition
public extension ReallyLazySequenceProtocol {
    //NB This only gets called when we are NOT a ChainedSequence, i.e. we are the root RLS in a chain
    // Hence the guard let below succeeds as a conversion to our output since on the actual RLS struct
    // there is a constraint that InputType == OutputType
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> InputDelivery {
        return {
            guard let value = $0 as? OutputType? else { return .done }
            return .more({ delivery(value) })
        }
    }
}

// ChainedSequences simply compose their composition with all successesors with their predecessor
// This recurses all the way back to the head sequence where it terminates because the head is NOT
// a ChainedSequence
public extension ChainedSequence {
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> InputDelivery  {
        return predecessor.compose(composer(delivery)) as! InputDelivery
    }
    
    public func listen(_ delivery: @escaping (OutputType?) -> Void) -> Void {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in
            delivery(value)
            return .done
        }
        let _ = predecessor.compose(composer(deliveryWrapper))
    }
}

// Implement Sequencing
// Each of the methods below composes a function from 3 different elements
// 1. Its predecessors composed function
// 2. It's own associated function which takes the predecessors output type and operates on it to produce its own output type
// 3. a particular function which is specific to the action being taken
// Number 3 is what is being passed in to the initializer of the specific types returned below

public extension ReallyLazySequenceProtocol {
    // Map sequential values of one type to a value of the same or different type and delivers them
    // to our successor using the successor's delivery closure
    public func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> Map<Self, T> {
        return Map<Self, T>(predecessor: self) { delivery in
            return { (input) -> ContinuationResult in
                guard let input = input else {return .more({ delivery(nil) }) }
                do {
                    let transformed = try transform(input)
                    return .more({ delivery(transformed) })
                } catch {
                    let rlsError = ContinuationError.context(input, delivery, error)
                    return .error(rlsError)
                }
            }
        }
    }
    
    // When the OutputType of the sequence is an optional, remove nils from the sequence, and transform
    // the non-optional type to the output type
    public func compactMap<T>(_ transform: @escaping (OutputType) -> T? ) -> CompactMap<Self, T> {
        return CompactMap<Self, T>(predecessor: self) { delivery in
            return { (optionalInput) -> ContinuationResult in
                guard let input = optionalInput else { return .more({ delivery(nil) }) } // termination nil
                guard let output = transform(input) else { return ContinuationResult.done }
                return .more({ delivery(output) }) // value to pass on
            }
        }
    }

    // A generalized form of reduce which allows collection of values until a condition is reached
    // Collected values are then forwarded as the collecting type to the successor when the until condition is met
    // this function allows the initial value to be reset before receiving input of nil
    // N.B.  This is the ONLY sequence function which maintains mutable internal state.  Setting
    // the partial value *MUST* be serialized
    public func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> Reduce<Self, T> {
        return Reduce<Self, T>(predecessor: self) { delivery in
            var partialValue = initialValue()
            var setNextPartialValue: Continuation?
            return { (input) -> ContinuationResult in
                do {
                    _ = try setNextPartialValue?(); setNextPartialValue = nil
                    guard let input = input else { return .afterThen( .more({ delivery(partialValue) }) , .more({ delivery(nil) }) ) }
                    partialValue = try combine(partialValue, input)
                    if until(partialValue, input) {
                        setNextPartialValue = { partialValue = initialValue(); return .done }
                        return .more({ delivery(partialValue) })
                    }
                    return .done
                } catch {
                    let rlsError = ContinuationError.context(input, delivery, error)
                    return ContinuationResult.error(rlsError)
                }
            }
        }
    }
    
    // Optionally in a specific queue, create a sequence of values from a single value
    // and then flatten that sequence into this one.  If queue is nil perform the operation in line
    func flatMap<T, U>(queue: OperationQueue?, _ transform: @escaping (OutputType) -> U) -> FlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T {
        return FlatMap<Self, T>(predecessor: self) { delivery in
            return { (input) -> ContinuationResult in
                guard let input = input else { return delivery(nil) }
                let generator = transform(input)
                    .consume { value in
                        guard let value = value else { return }
                        //FIXME: This should go up to the main continuation loop
                        // and not be completed from here..
                        _ = ContinuationResult.complete(.more({ delivery(value) }))
                    }
                if let queue = queue {
                    queue.addOperation { try? generator.process(input) }
                } else {
                    try? generator.process(input)
                }
                return .done
            }
        }
    }

    // In the current queue, create a sequence of values from a single value
    // and then flatten the resulting sequence into this one
    func flatMap<T, U>(_ transform: @escaping (OutputType) -> U) -> FlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T {
        return flatMap(queue: nil, transform)
    }
    
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> Reduce<Self, T> {
        return collect(initialValue: initialValue, combine: combine, until: { $1 == nil })
    }

    // filter values that do not meet a specified condition
    func filter(_ filter: @escaping (OutputType) -> Bool ) -> Filter<Self, OutputType> {
        return Filter<Self, OutputType>(predecessor: self) { delivery in
            return { (input) in (input == nil || filter(input!)) ?  .more({ delivery(input) }) :  .done }
        }
    }
    
    // Perform the rest of the push on another dispatch queue
    public func dispatch(_ queue: OperationQueue) -> Dispatch<Self, OutputType> {
        return Dispatch<Self, OutputType>(predecessor: self) { delivery in
            return { (input) -> ContinuationResult in
                queue.addOperation { _ = ContinuationResult.complete(delivery(input)) }; return .done
            }
        }
    }
}



