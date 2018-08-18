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
// in-line when processing an RLS. They continue the current computation
// in a stack frame much closer to the users invocation.

public protocol ContinuationErrorContextProtocol: Error { }

public struct ContinuationErrorContext<T, U>: ContinuationErrorContextProtocol, Equatable {
    var opType: ReallyLazySequenceOperationType
    var value: T
    var delivery: (U?) throws -> ContinuationResult
    var error: Error

    public static func == (lhs: ContinuationErrorContext<T, U>, rhs: ContinuationErrorContext<T, U>) -> Bool {
            return lhs.opType == rhs.opType
                && (type(of: lhs.value)    == type(of: rhs.value))
                && (type(of: lhs.delivery) == type(of: rhs.delivery))
                && (type(of: lhs.error)    == type(of: rhs.error))
    }
}

public typealias Continuation = () throws -> ContinuationResult

typealias ContinuationErrorHandler = (ContinuationErrorContextProtocol) -> ContinuationResult

public let ContinuationDone = { () -> ContinuationResult in ContinuationResult.done }

public indirect enum ContinuationResult: Equatable {
    case more(Continuation)
    case error(ContinuationErrorContextProtocol)
    case afterThen(ContinuationResult, ContinuationResult)
    case done
    
    public static func == (lhs: ContinuationResult, rhs: ContinuationResult) -> Bool {
        switch (lhs, rhs) {
        case (.done, .done): return true
        case (.more, .more): return true
        case (.error, .error): return true
        case (let .afterThen(after1, then1), let .afterThen(after2, then2)):
            return after1 == after2 && then1 == then2
        default:
            return false
        }
    }
    
    init() {
        self = .done
    }
    
    init(_ continuation: @escaping Continuation) {
        self = .more(continuation)
    }
    
    init(_ continuation: ContinuationResult, _ after: ContinuationResult) {
        self = .afterThen(continuation, after)
    }
    
    var canContinue: Bool {
        switch self {
        case .done: return false
        case .more, .error, .afterThen: return true
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
            do {
                return (try continuation(), stack)
            } catch {
                guard let rlsError = error as? ContinuationErrorContextProtocol else { return (.done, stack) }
                return (.error(rlsError), stack)
            }
        case .error(let error):
            return (errorHandler(error), stack)
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
