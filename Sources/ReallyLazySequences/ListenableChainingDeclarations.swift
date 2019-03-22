//
//  ListenableChainingDeclarations.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/19/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public struct ListenableMap<Predecessor: ListenableSequenceProtocol, Output>: ChainedListenerProtocol {
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
        self.description = standardizeRLSDescription("\(predecessor.description) >> LMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableReduce<Predecessor: ListenableSequenceProtocol, Output>: ChainedListenerProtocol {
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
        self.description = standardizeRLSDescription("\(predecessor.description) >> LReduce<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableFilter<Predecessor: ListenableSequenceProtocol, Output>: ChainedListenerProtocol {
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
        self.description = standardizeRLSDescription("\(predecessor.description) >> LFilter<\(type(of:Predecessor.OutputType.self))>")
    }
}

public struct ListenableFlatMap<Predecessor: ListenableSequenceProtocol, Output>: ChainedListenerProtocol {
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
        self.description = standardizeRLSDescription("\(predecessor.description) >> LFlatMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableCompactMap<Predecessor: ListenableSequenceProtocol, Output>: ChainedListenerProtocol {
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
        self.description = standardizeRLSDescription("\(predecessor.description) >> LCompactMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableDispatch<Predecessor: ListenableSequenceProtocol, Output>: ChainedListenerProtocol {
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
        self.description = standardizeRLSDescription("\(predecessor.description) >> LDispatchMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}
