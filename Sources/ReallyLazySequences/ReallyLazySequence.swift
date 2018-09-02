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

public protocol SubsequenceProtocol: ConsumableProtocol {
    var generator: (InputType, @escaping (OutputType?) -> Void) -> Void { get set }
    init(_ generator: @escaping (InputType, @escaping (OutputType?) -> Void) -> Void)
}

public struct Subsequence<T, U>: SubsequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = U
    
    public var description: String = standardizeRLSDescription("GeneratingSubsequence<\(type(of:T.self), type(of:U.self))>")
    public var generator: (T, @escaping (U?) -> Void) -> Void
    
    public init(_ generator: @escaping (T, @escaping (U?) -> Void) -> Void) {
        self.generator = generator
    }
}

public protocol StatefulSubsequenceProtocol: ConsumableProtocol {
    associatedtype State
    var state: State { get set }
    var generator: (InputType, State, @escaping (OutputType?) -> Void) -> Void { get set }
    init(_ initialState: State, _ generator: @escaping (InputType, State, @escaping (OutputType?) -> Void) -> Void)
}


