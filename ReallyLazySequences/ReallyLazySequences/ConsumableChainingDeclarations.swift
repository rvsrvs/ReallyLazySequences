//
//  ConsumableChainingDeclarations.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/28/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

//===================================================================================
// structs for Chaining.  These only make it easier to read the types of an RLS
// using type(of:).  The introduction of higher kinded types (HKTs) in Swift would
// make this not require all the boilerplate. 
//===================================================================================

public struct ConsumableMap<Predecessor: ConsumableSequenceProtocol, Output>: ConsumableChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = "\(predecessor.description) >> CMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>"
            .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")
    }
}

public struct ConsumableReduce<Predecessor: ConsumableSequenceProtocol, Output>: ConsumableChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = "\(predecessor.description) >> CReduce<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>"
            .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")
    }
}

public struct ConsumableFilter<Predecessor: ConsumableSequenceProtocol, Output>: ConsumableChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = "\(predecessor.description) >> CFilter<\(type(of:Predecessor.OutputType.self))>"
            .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")
    }
}

public struct ConsumableFlatMap<Predecessor: ConsumableSequenceProtocol, Output>: ConsumableChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = "\(predecessor.description) >> CFlatMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>"
            .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")
    }
}

public struct ConsumableCompactMap<Predecessor: ConsumableSequenceProtocol, Output>: ConsumableChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = "\(predecessor.description) >> CCompactMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>"
            .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")
    }
}

public struct ConsumableDispatch<Predecessor: ConsumableSequenceProtocol, Output>: ConsumableChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = "\(predecessor.description) >> CDispatch<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>"
            .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")
    }
}

