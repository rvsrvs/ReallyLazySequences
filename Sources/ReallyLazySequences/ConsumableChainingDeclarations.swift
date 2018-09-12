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

public struct ConsumableMap<Predecessor: ConsumableProtocol, Output>: ChainedConsumableProtocol {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = standardizeRLSDescription("\(predecessor.description) >> CMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ConsumableReduce<Predecessor: ConsumableProtocol, Output>: ChainedConsumableProtocol {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = standardizeRLSDescription("\(predecessor.description) >> CReduce<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ConsumableFilter<Predecessor: ConsumableProtocol, Output>: ChainedConsumableProtocol {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = standardizeRLSDescription("\(predecessor.description) >> CFilter<\(type(of:Predecessor.OutputType.self))>")
    }
}

public struct ConsumableFlatMap<Predecessor: ConsumableProtocol, Output>: ChainedConsumableProtocol {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = standardizeRLSDescription("\(predecessor.description) >> CFlatMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ConsumableCompactMap<Predecessor: ConsumableProtocol, Output>: ChainedConsumableProtocol {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = standardizeRLSDescription("\(predecessor.description) >> CCompactMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ConsumableAsyncMap<Predecessor: ConsumableProtocol, Output>: ChainedConsumableProtocol {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = standardizeRLSDescription("\(predecessor.description) >> CAsyncMap<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

public struct ConsumableDispatch<Predecessor: ConsumableProtocol, Output>: ChainedConsumableProtocol {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var description: String
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
        self.description = standardizeRLSDescription("\(predecessor.description) >> CDispatch<\(type(of:Predecessor.OutputType.self)) -> \(type(of:Output.self))>")
    }
}

