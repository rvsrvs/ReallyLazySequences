//
//  Continuation.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//

/*
 Copyright 2019, Ronald V. Simmons
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

// Continuations represent a computation which can be continued at a later time
// They are a way of avoiding enormous convoluted stack frames that emerge from
// composing a chain of functions in an RLS and of attaching error handling
// in-line when processing an RLS. They continue the current computation
// in a stack frame much closer to the users invocation.  This, most importantly,
// allows the consumer to handle errors as they arise rather than well
// after the fact.

public typealias Continuation = () throws -> ContinuationResult
typealias ContinuationErrorHandler = (ContinuationErrorContextProtocol) -> ContinuationResult

public protocol ContinuationErrorContextProtocol: Error { }

public enum ContinuationTermination: Equatable {
    case canContinue
    case terminate
}

public struct ContinuationErrorContext<T, U>: ContinuationErrorContextProtocol {
    var value: T
    var delivery: (U?) throws -> ContinuationResult
    var error: Error
}

public indirect enum ContinuationResult {
    case more(Continuation)
    case error(ContinuationErrorContextProtocol)
    case afterThen(ContinuationResult, ContinuationResult)
    case done(ContinuationTermination)
        
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
        case .done(let termination):
            return (.done(termination), stack)
        case .more(let continuation):
            do {
                return (try continuation(), stack)
            } catch {
                guard let rlsError = error as? ContinuationErrorContextProtocol else { return (.done(.canContinue), stack) }
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
        errorHandler: @escaping ContinuationErrorHandler = { _ in .done(.canContinue) }
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
