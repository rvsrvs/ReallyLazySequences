//
//  ChainingDeclarations.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/28/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

//===================================================================================
// structs for Chaining.  These only make it easier to read the types of an RLS
// using type(of:).  I suspect that the introduction of higher kinded types would
// make this not require all the cut'n'paste.
// Swift needs a way for me to do this without boiler plate
//===================================================================================

public struct Map<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Reduce<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Filter<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Sort<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct FlatMap<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Dispatch<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

public struct Collect<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

// Template struct for chaining.  All of the specific structs like Map, Reduce, etc
// could be just ReallyLazyChainedSequences but
// we create different structs so that the Sequence operations can be read directly from the type
// Map, Reduce, et al, look EXACTLY like this definition only with a different name
// This struct would only be used if it is decided that reading those types is not valueable
// which is unlikely
public struct ReallyLazyChainedSequence<Predecessor: ReallyLazySequenceProtocol, Output>: ChainedSequence {
    public typealias PredecessorType = Predecessor
    public typealias InputType = Predecessor.InputType
    public typealias OutputType = Output
    
    public var predecessor: Predecessor
    public var composer: Composer
    
    public init(predecessor: PredecessorType, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
}

