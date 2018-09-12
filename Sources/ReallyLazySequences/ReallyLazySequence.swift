//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public protocol ReallyLazySequenceProtocol: CustomStringConvertible {
    associatedtype InputType  // The _initial_ initial type for the head for a given RLS chain
    associatedtype OutputType // The type which is output from a given RLS
    
    typealias ContinuableInputDelivery  = (Self.InputType?) throws -> ContinuationResult
    typealias ContinuableOutputDelivery = (OutputType?) -> ContinuationResult
    typealias TerminalOutputDelivery    = (OutputType?) -> ContinuationTermination

    func compose(_ output: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery?
}

public struct SimpleSequence<T>: ConsumableProtocol {
    public var description: String = standardizeRLSDescription("SimpleSequence<\(type(of:T.self))>")
    public typealias InputType = T
    public typealias OutputType = T
    public init() { }    
}

public struct Subsequence<T, U> {
    public typealias InputType = T
    public typealias OutputType = U
    
    public var description: String = standardizeRLSDescription("Subsequence<\(type(of:T.self), type(of:U.self))>")
    public var iterator: () -> OutputType?

    public init(_ iterator: @escaping () -> OutputType?) {
        self.iterator = iterator
    }
    
    public init<V>(_ sequence: V) where V: Sequence, V.Element == OutputType {
        var iterator = sequence.makeIterator()
        self.iterator = { () -> OutputType? in
            return iterator.next()
        }
    }

    public init<V: Sequence>(_ sequence: V, transform: @escaping (V.Element) -> OutputType) {
        var iterator = sequence.makeIterator()
        self.iterator = { () -> OutputType? in
            guard let next = iterator.next() else { return nil }
            return transform(next)
        }
    }
}
