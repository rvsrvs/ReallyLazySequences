//
//  Composers.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/19/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

struct Composers {
    static func mapComposer<T, U>(
        delivery: @escaping (T?) -> ContinuationResult,
        transform: @escaping (U) throws -> T
    ) -> (U?) -> ContinuationResult {
        return { (input: U?) -> ContinuationResult in
            guard let input = input else {return .more({ delivery(nil) }) }
            do {
                let transformed = try transform(input)
                return .more({ delivery(transformed) })
            } catch {
                let rlsError = ContinuationErrorContext(opType: .map, value: input, delivery: delivery, error: error)
                return .error(rlsError)
            }
        }
    }
    
    static func compactMapComposer<T, U>(
        delivery: @escaping (T?) -> ContinuationResult,
        transform: @escaping (U) throws -> T?
    ) -> (U?) -> ContinuationResult {
        return { (optionalInput: U?) -> ContinuationResult in
            guard let input = optionalInput else { return .more({ delivery(nil) }) } // termination nil
            do {
                guard let transformed = try transform(input) else { return .done(.canContinue) }
                return .more({ delivery(transformed) }) // value to pass on
            } catch {
                let rlsError = ContinuationErrorContext(opType: .compactMap, value: input, delivery: delivery, error: error)
                return ContinuationResult.error(rlsError)
            }
        }
    }
    
    static func collectComposer<T,U> (
        delivery: @escaping (T?) -> ContinuationResult,
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, U) throws -> T,
        until: @escaping (T, U?) -> Bool
    ) -> (U?) -> ContinuationResult {
        var partialValue = initialValue()
        return { (input: U?) -> ContinuationResult in
            do {
                guard let input = input else {
                    return .afterThen(
                        .more({ delivery(partialValue) }),
                        .more({ delivery(nil) })
                    )
                }
                partialValue = try combine(partialValue, input)
                if until(partialValue, input) {
                    return .afterThen(
                        .more({ delivery(partialValue) }),
                        .more({ partialValue = initialValue(); return .done(.canContinue) })
                    )
                }
                return .done(.canContinue)
            } catch {
                let rlsError = ContinuationErrorContext(opType: .reduce, value: input, delivery: delivery, error: error)
                return ContinuationResult.error(rlsError)
            }
        }
    }
    
    static func filterComposer<T> (
        delivery: @escaping (T?) -> ContinuationResult,
        filter: @escaping (T) throws -> Bool
    ) -> (T?) -> ContinuationResult {
        return { (input: T?) -> ContinuationResult in
            do {
                guard let input = input else { return .more({ delivery(nil) })}
                let result = try filter(input)
                return result ? .more({ delivery(input) }) :  .done(.canContinue)
            } catch {
                let rlsError = ContinuationErrorContext(opType: .filter, value: input, delivery: delivery, error: error)
                return ContinuationResult.error(rlsError)
            }
        }
    }
    
    static func dispatchComposer<T> (
        delivery: @escaping (T?) -> ContinuationResult,
        queue: OperationQueue
    ) -> (T?) -> ContinuationResult {
        return { (input: T?) -> ContinuationResult in
            queue.addOperation { _ = ContinuationResult.complete(delivery(input)) }
            return .done(.canContinue)
        }
    }
    
    typealias SubsequenceContinuation = () -> Any?
    static func flatMapComposer<T, U, V> (
        delivery: @escaping (T?) -> ContinuationResult,
        transform: @escaping (U) throws -> V
    ) -> (U?) -> ContinuationResult where V: SubsequenceProtocol, V.InputType == U, V.OutputType == T {
        return { (input: U?) -> ContinuationResult in
            guard let input = input else { return delivery(nil) }
            do {
                let generator = try transform(input).generator
                func iterator(generator: SubsequenceContinuation) -> ContinuationResult {
                    guard let value = generator() as? (T, SubsequenceContinuation) else { return .done(.canContinue) }
                    return .afterThen(
                        .more({ delivery(value.0) }),
                        .more({ iterator(generator: value.1) })
                    )
                }
                return iterator(generator: generator)
            } catch {
                let rlsError = ContinuationErrorContext(opType: .flatMap, value: input, delivery: delivery, error: error)
                return ContinuationResult.error(rlsError)
            }
        }
    }
}

