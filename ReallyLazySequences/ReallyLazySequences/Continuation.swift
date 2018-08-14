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

// Ideally *Any* would be replaced with ContinuationResult but swift does not allow
// recursive type definitions
public typealias AnonymousContinuation = () -> Any

public let ContinuationDone = {() -> ContinuationResult in ContinuationResult.done }

public enum ContinuationResult {
    case more(AnonymousContinuation)
    case after(AnonymousContinuation, AnonymousContinuation)
    case done
    
    init() {
        self = .done
    }
    
    init(continuation: @escaping Continuation) {
        self = .more(continuation)
    }
    
    init(continuation: @escaping Continuation, after: @escaping Continuation) {
        self = .after(continuation, after)
    }
    
    var canContinue: Bool {
        switch self {
        case .done: return false
        case .more, .after: return true
        }
    }
    
    var next: ContinuationResult {
        switch self {
        case .done:
            return .done
        case .more(let continuation):
            guard let result = continuation() as? ContinuationResult else { return .done }
            return result
        case .after(let continuation1, let continuation2):
            guard let result = continuation1() as? ContinuationResult else { return .more(continuation2) }
            switch result {
            case .done: return .more(continuation2)
            case .more(let continuation1a): return .after(continuation1a, continuation2)
            case .after: return result.next
            }
        }
    }
    
    static func complete(_ result: ContinuationResult) -> ContinuationResult {
        var current = result
        while current.canContinue { current = current.next }
        return current
    }
    
    static func complete(_ continuation: @escaping AnonymousContinuation) -> ContinuationResult {
        guard let continuation = continuation as? Continuation else { return .done }
        let result = continuation();
        return complete(result)
    }
}
