//
//  ListenableChainingDeclarations.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/19/18.
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

public struct ListenableMap<Predecessor: ObservableSequenceProtocol, Output>: ChainedObservableSequenceProtocol {
    public typealias ListenableType = Predecessor.ListenableType
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = Utilities.standardizeDescription("\(predecessor.description) >> LMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableReduce<Predecessor: ObservableSequenceProtocol, Output>: ChainedObservableSequenceProtocol {
    public typealias ListenableType = Predecessor.ListenableType
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = Utilities.standardizeDescription("\(predecessor.description) >> LReduce<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableFilter<Predecessor: ObservableSequenceProtocol, Output>: ChainedObservableSequenceProtocol {
    public typealias ListenableType = Predecessor.ListenableType
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = Utilities.standardizeDescription("\(predecessor.description) >> LFilter<\(type(of:Predecessor.OutputType.self))>")
    }
}

public struct ListenableFlatMap<Predecessor: ObservableSequenceProtocol, Output>: ChainedObservableSequenceProtocol {
    public typealias ListenableType = Predecessor.ListenableType
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = Utilities.standardizeDescription("\(predecessor.description) >> LFlatMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableCompactMap<Predecessor: ObservableSequenceProtocol, Output>: ChainedObservableSequenceProtocol {
    public typealias ListenableType = Predecessor.ListenableType
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = Utilities.standardizeDescription("\(predecessor.description) >> LCompactMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableDispatch<Predecessor: ObservableSequenceProtocol, Output>: ChainedObservableSequenceProtocol {
    public typealias ListenableType = Predecessor.ListenableType
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = Utilities.standardizeDescription("\(predecessor.description) >> LDispatchMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}
