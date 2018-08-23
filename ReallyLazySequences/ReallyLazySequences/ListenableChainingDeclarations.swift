//
//  ListenableChainingDeclarations.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/19/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public struct ListenableMap<Predecessor: ListenerProtocol, Output>: ListenableChainedSequence {    
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
        self.description = standardize("\(predecessor.description) >> LMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableReduce<Predecessor: ListenerProtocol, Output>: ListenableChainedSequence {
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
        self.description = standardize("\(predecessor.description) >> LReduce<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableFilter<Predecessor: ListenerProtocol, Output>: ListenableChainedSequence {
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
        self.description = standardize("\(predecessor.description) >> LFilter<\(type(of:Predecessor.OutputType.self))>")
    }
}

public struct ListenableFlatMap<Predecessor: ListenerProtocol, Output>: ListenableChainedSequence {
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
        self.description = standardize("\(predecessor.description) >> LFlatMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableCompactMap<Predecessor: ListenerProtocol, Output>: ListenableChainedSequence {
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
        self.description = standardize("\(predecessor.description) >> LCompactMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ListenableDispatch<Predecessor: ListenerProtocol, Output>: ListenableChainedSequence {
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
        self.description = standardize("\(predecessor.description) >> LDispatchMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}
