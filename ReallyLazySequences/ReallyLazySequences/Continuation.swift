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
    case after(ContinuationResult, ContinuationResult)
    case done
    
    init() {
        self = .done
    }
    
    init(continuation: @escaping Continuation) {
        self = .more(continuation)
    }
    
    init(continuation: ContinuationResult, after: ContinuationResult) {
        self = .after(continuation, after)
    }
    
    var canContinue: Bool {
        switch self {
        case .done: return false
        case .more, .moreThrows, .after: return true
        }
    }
    
    private func next(errorHandler: @escaping ContinuationErrorHandler) -> ContinuationResult {
        switch self {
        case .done:
            return .done
        case .more(let continuation):
            guard let result = continuation() as? ContinuationResult else { return .done }
            return result
        case .moreThrows(let continuation):
            do {
                guard let result = try continuation() as? ContinuationResult else { return .done }
                return result
            } catch {
                return errorHandler(error)
            }
        case .after(let result1, let result2):
            switch result1 {
            case .done: return result2
            case .more(let continuation):
                guard let result1a = continuation() as? ContinuationResult else { return result2 }
                return .after(result1a, result2)
            case .moreThrows(let continuation):
                do {
                    guard let result1a = try continuation() as? ContinuationResult else { return result2 }
                    return .after(result1a, result2)
                } catch {
                    return errorHandler(error)
                }
            case .after:
                return ContinuationResult.complete(result1, errorHandler: errorHandler)
            }
        }
    }
    
    static func complete(
        _ result: ContinuationResult,
        errorHandler: @escaping ContinuationErrorHandler = { _ in .done }
    ) -> ContinuationResult {
        var current = result
        while current.canContinue { current = current.next(errorHandler: errorHandler) }
        return current
    }
    
    static func complete(
        _ continuation: @escaping AnonymousContinuation,
        errorHandler: ContinuationErrorHandler = { _ in .done }
    ) -> ContinuationResult {
        guard let continuation = continuation as? Continuation else { return .done }
        let result = ContinuationResult.more(continuation);
        return complete(result)
    }

    static func complete(
        _ continuation: @escaping AnonymousThrowingContinuation,
        errorHandler: ContinuationErrorHandler = { _ in .done }
    ) -> ContinuationResult {
        guard let continuation = continuation as? ThrowingContinuation else { return .done }
        let result = ContinuationResult.moreThrows(continuation)
        return complete(result)
    }
}
