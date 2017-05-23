//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

public protocol Composable {
    associatedtype OutputType
    associatedtype HeadType
    func compose(_ output: @escaping (OutputType?) -> Continuation) -> ((HeadType?) -> Continuation)
    func map<U>(_ transform: @escaping (OutputType) -> U ) -> Chain.Map<Self, U>
}

public extension Composable {
    public func map<T>(_ transform: @escaping (OutputType) -> T ) -> Chain.Map<Self, T> {
        return Chain.Map<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((OutputType?) -> Continuation) in
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { return { delivery(nil) } }
                return { delivery(transform(input)) }
            }
        }
    }
}

public protocol ChainedComposable: Composable {
    associatedtype PredecessorType: Composable
    typealias Composer = (@escaping (OutputType?) -> Continuation) -> ((PredecessorType.OutputType?) -> Continuation)
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
    func compose(_ output: @escaping (OutputType?) -> Continuation) -> ((PredecessorType.HeadType?) -> Continuation)
}

public extension ChainedComposable {
    public func compose(_ output: @escaping (OutputType?) -> Continuation) -> ((PredecessorType.HeadType?) -> Continuation) {
        let composition = self.composer(output)
        return predecessor.compose(composition)
    }
}

public struct Chain {
    public struct Map<Predecessor: Composable, Output>: ChainedComposable {
        public typealias PredecessorType = Predecessor
        public typealias HeadType = Predecessor.HeadType
        public typealias OutputType = Output
        
        public var predecessor: Predecessor
        public var composer: Composer
        
        public init(predecessor: PredecessorType, composer: @escaping Composer) {
            self.predecessor = predecessor
            self.composer = composer
        }
    }
}
