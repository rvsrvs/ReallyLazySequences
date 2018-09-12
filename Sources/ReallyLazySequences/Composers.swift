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
    
    static func statefulMapComposer<State, Input, Output>(
        delivery: @escaping (Output?) -> ContinuationResult,
        initialState: @escaping @autoclosure () -> State,
        updateState: @escaping (State, Input) throws -> State,
        transform: @escaping (State, Input) throws -> Output
    ) -> (Input?) -> ContinuationResult {
        let stateLock = NSLock()
        var state = initialState()
        return { (input: Input?) -> ContinuationResult in
            guard let input = input else { return .more({ delivery(nil) }) }
            stateLock.lock()
            do {
                state = try updateState(state, input)
            } catch {
                return .done(.terminate)
            }
            stateLock.unlock()
            do {
                state = try updateState(state, input)
                let output = try transform(state, input)
                return .more({ delivery(output) })
            } catch {
                let rlsError = ContinuationErrorContext(opType: .reduce, value: input, delivery: delivery, error: error)
                return ContinuationResult.error(rlsError)
            }
        }
    }

    static func flatMapComposer<T, U> (
        delivery: @escaping (T?) -> ContinuationResult,
        transform: @escaping (U) throws -> Subsequence<U, T>
    ) -> (U?) -> ContinuationResult {
        return { (input: U?) -> ContinuationResult in
            guard let input = input else { return delivery(nil) }
            do {
                let iterator = try transform(input).iterator
                func iterate(_ iterator: @escaping () -> T?) -> ContinuationResult {
                    guard let value = iterator() else { return .done(.canContinue) }
                    return .afterThen(
                        .more({ delivery(value) }),
                        .more({ iterate(iterator) })
                    )
                }
                return iterate(iterator)
            } catch {
                let rlsError = ContinuationErrorContext(opType: .flatMap, value: input, delivery: delivery, error: error)
                return ContinuationResult.error(rlsError)
            }
        }
    }

    static func statefulFlatMapComposer<State, Input, Output>(
        delivery: @escaping (Output?) -> ContinuationResult,
        initialState: @escaping @autoclosure () -> State,
        updateState: @escaping (State, Input) throws -> State,
        transform: @escaping (State, Input) throws -> Subsequence<Input, Output>
    ) -> (Input?) -> ContinuationResult {
        var stateLock = NSLock()
        var state = initialState()
        return { (input: Input?) -> ContinuationResult in
            guard let input = input else { return .more({ delivery(nil) }) }
            stateLock.lock()
            do {
                state = try updateState(state, input)
            } catch {
                return .done(.terminate)
            }
            stateLock.unlock()
            do {
                let iterator = try transform(state, input).iterator
                func iterate(_ iterator: @escaping () -> Output?) -> ContinuationResult {
                    guard let value = iterator() else { return .done(.canContinue) }
                    return .afterThen(
                        .more({ delivery(value) }),
                        .more({ iterate(iterator) })
                    )
                }
                return iterate(iterator)
            } catch {
                let rlsError = ContinuationErrorContext(opType: .reduce, value: input, delivery: delivery, error: error)
                return ContinuationResult.error(rlsError)
            }
        }
    }
    

    static func compactMapComposer<Input, Output>(
        delivery: @escaping (Output?) -> ContinuationResult,
        transform: @escaping (Input) throws -> Output?
    ) -> (Input?) -> ContinuationResult {
        return { (input: Input?) -> ContinuationResult in
            do {
                guard let input = input else { return .more({ delivery(nil) })}
                guard let output = try transform(input) else { return .done(.canContinue) }
                return .more({ delivery(output) })
            } catch {
                let rlsError = ContinuationErrorContext(opType: .reduce, value: input, delivery: delivery, error: error)
                return ContinuationResult.error(rlsError)
            }
        }
    }
    
    static func statefulCompactMapComposer<State, Input, Output>(
        delivery: @escaping (Output?) -> ContinuationResult,
        initialState: @escaping @autoclosure () -> State,
        updateState: @escaping (State, Input?) throws -> State,
        transform: @escaping (State, Input?) throws -> Output?
    ) -> (Input?) -> ContinuationResult {
        let stateLock = NSLock()
        var state = initialState()
        return { (input: Input?) -> ContinuationResult in
            stateLock.lock()
            do {
                state = try updateState(state, input)
            } catch {
                return .done(.terminate)
            }
            stateLock.unlock()
            do {
                let output = try transform(state, input)
                switch (input, output) {
                case (.none, .none):
                    return .more({ delivery(nil) })
                case (.none, .some(let output)):
                    return .afterThen(
                        .more({ delivery(output) }),
                        .more({ delivery(nil) })
                    )
                case (.some, .none):
                    return .done(.canContinue)
                case (.some, .some(let output)):
                    return .more({ delivery(output) })
                }
            } catch {
                let rlsError = ContinuationErrorContext(opType: .reduce, value: input, delivery: delivery, error: error)
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
}

