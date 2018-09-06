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

public protocol SubsequenceProtocol {
    associatedtype InputType
    associatedtype OutputType
    typealias SubsequenceContinuation = () -> Any?
    typealias SubsequenceResult = (OutputType, SubsequenceContinuation)
    var generator: SubsequenceContinuation { get }
    init(generator: @escaping SubsequenceContinuation)
}

public struct Subsequence<T, U>: SubsequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = U
    
    public var description: String = standardizeRLSDescription("Subsequence<\(type(of:T.self), type(of:U.self))>")
    public var generator: SubsequenceContinuation
    
    public init(generator:@escaping SubsequenceContinuation) {
        self.generator = generator
    }
}

public protocol StatefulSubsequenceProtocol {
    associatedtype InputType
    associatedtype OutputType
    typealias SubsequenceContinuation = () -> Any?
    typealias StatefulSubsequenceResult = (State, OutputType, SubsequenceContinuation)
    associatedtype State
    var state: State { get set }
    var generator: (State, InputType) -> (State, OutputType, SubsequenceContinuation)? { get }
    init(_ generator: @escaping (State, InputType) -> StatefulSubsequenceResult?)
}
