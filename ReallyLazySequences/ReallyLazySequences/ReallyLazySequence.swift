//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
    
    var successful: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
}

public enum ReallyLazySequenceOperationType: Equatable {
    case map
    case flatMap
    case compactMap
    case reduce
    case filter
}

public enum ReallyLazySequenceError: Error {
    case isComplete
    case nonPushable
    case noListeners
    
    var description: String {
        switch self {
        case .isComplete:
            return "ReallyLazySequence has already completed.  Pushes not allowed"
        case .nonPushable:
            return "push may only be called on Sequences which are NOT already attached to producers"
        case .noListeners:
            return "No listeners available for producer to produce into"
        }
    }
}

public protocol ReallyLazySequenceProtocol: CustomStringConvertible {
    associatedtype InputType  // The _initial_ initial type for the head for a given RLS chain
    associatedtype OutputType // The type which is output from a given RLS
    
    typealias ContinuableInputDelivery  = (Self.InputType?) throws -> ContinuationResult
    typealias ContinuableOutputDelivery = (OutputType?) -> ContinuationResult
    typealias TerminalOutputDelivery = (OutputType?) -> Void

    // The function which is called from the tail of an RLS chain to cause it
    // to create its composed function  
    func compose(_ output: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery
}

public struct SimpleSequence<T>: ConsumableSequenceProtocol {
    public var description: String = "SimpleSequence<\(type(of:T.self))>"
        .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")
    public typealias InputType = T
    public typealias OutputType = T
    public init() { }    
}

public protocol SubsequenceProtocol: ConsumableSequenceProtocol {
    var generator: (InputType, @escaping (OutputType?) -> Void) -> Void { get set }
    init(_ generator: @escaping (InputType, @escaping (OutputType?) -> Void) -> Void)
}

public extension SubsequenceProtocol {
    func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery {
        let deliveryWrapper = { (output: OutputType?) -> Void in
            _ = ContinuationResult.complete(delivery(output));
            return
        }
        return { (input: InputType?) throws -> ContinuationResult in
            guard let input = input else { return delivery(nil) }
            return .more ({ self.generator(input, deliveryWrapper); return ContinuationResult.done })
        }
    }
}

public struct GeneratingSequence<T, U>: SubsequenceProtocol {
    public var description: String = "GeneratingSubsequence<\(type(of:T.self), type(of:U.self))>"
        .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")
    
    public typealias InputType = T
    public typealias OutputType = U
    public var generator: (T, @escaping (U?) -> Void) -> Void
    
    public init(_ generator: @escaping (T, @escaping (U?) -> Void) -> Void) {
        self.generator = generator
    }
}
