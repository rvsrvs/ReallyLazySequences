//
//  Continuation.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

// Continuations represent at computation which can be continued at a later time
// They are a way of avoiding enormous convoluted stack frames that emerge from
// composing a chain of functions in an RLS and of attaching error handling
// in-line when processing and RLS. They continue the current computation
// in a stack frame much closer to the users invocation.

public typealias Continuation = () -> ContinuationResult
public typealias ThrowingContinuation = () throws -> ContinuationResult

// Ideally *Any* would be replaced with ContinuationResult but swift does not allow
// recursive type definitions
public typealias AnonymousContinuation = () -> Any
public typealias AnonymousThrowingContinuation = () throws -> Any

typealias ContinuationErrorHandler = (Error) -> ContinuationResult

public let ContinuationDone = { () -> ContinuationResult in ContinuationResult.done }

public indirect enum ContinuationResult {
    case more(AnonymousContinuation)
    case moreThrows(AnonymousThrowingContinuation)
    case afterThen(ContinuationResult, ContinuationResult)
    case done
    
    init() {
        self = .done
    }
    
    init(continuation: @escaping Continuation) {
        self = .more(continuation)
    }
    
    init(continuation: ContinuationResult, after: ContinuationResult) {
        self = .afterThen(continuation, after)
    }
    
    var canContinue: Bool {
        switch self {
        case .done: return false
        case .more, .moreThrows, .afterThen: return true
        }
    }
    
    private func next(
        using stack:[ContinuationResult],
        errorHandler: @escaping ContinuationErrorHandler
    ) -> (ContinuationResult, [ContinuationResult]) {
        switch self {
        case .done:
            return (.done, stack)
        case .more(let continuation):
            guard let result = continuation() as? ContinuationResult else { return (.done, stack) }
            return (result, stack)
        case .moreThrows(let continuation):
            do {
                guard let result = try continuation() as? ContinuationResult else { return (.done, stack) }
                return (result, stack)
            } catch {
                return (errorHandler(error), stack)
            }
        case .afterThen(let result1, let result2):
            let newStack = [result2] + stack
            return (result1, newStack)
        }
    }
    
    static func complete(
        _ result: ContinuationResult,
        errorHandler: @escaping ContinuationErrorHandler = { _ in .done }
    ) -> ContinuationResult {
        var current = result
        var stack = [ContinuationResult]()
        while current.canContinue {
            (current, stack) = current.next(using: stack, errorHandler: errorHandler)
            if !current.canContinue && stack.count > 0 {
                current = stack[0]; stack = Array(stack.dropFirst())
            }
        }
        return current
    }
}
