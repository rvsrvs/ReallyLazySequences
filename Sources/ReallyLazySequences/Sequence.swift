//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//

/*
 Copyright 2019, Ronald V. Simmons
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public protocol SequenceProtocol: CustomStringConvertible {
    associatedtype InputType  // The _initial_ initial type for the head for a given RLS chain
    associatedtype OutputType // The type which is output from a given RLS
    
    typealias ContinuableInputDelivery  = (Self.InputType?) throws -> ContinuationResult
    typealias ContinuableOutputDelivery = (OutputType?) -> ContinuationResult
    typealias TerminalOutputDelivery    = (OutputType?) -> ContinuationTermination
    
    func compose(_ output: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery?
}

public struct Utilities {
    public static func standardizeDescription(_ description: String) -> String {
        return description
            .replacingOccurrences(of: ".Type", with: "")
            .replacingOccurrences(of: "Swift.", with: "")
    }
}

public struct SequenceHead<T>: ConsumableSequenceProtocol {
    public var description: String = Utilities.standardizeDescription("SimpleSequence<\(type(of:T.self))>")
    public typealias InputType = T
    public typealias OutputType = T
    public init() { }    
}

public struct Subsequence<T, U> {
    public typealias InputType = T
    public typealias OutputType = U
    
    public var description: String = Utilities.standardizeDescription("Subsequence<\((type(of:T.self), type(of:U.self)))>")
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
