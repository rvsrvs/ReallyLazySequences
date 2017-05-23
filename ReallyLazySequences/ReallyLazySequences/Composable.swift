//
//  Composable.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/23/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

fileprivate let nilContinuation: Continuation = { nil }

public protocol Composable {
    associatedtype OutputType
    associatedtype HeadType
    func compose(_ output: @escaping (OutputType?) -> Continuation) -> ((HeadType?) -> Continuation)
    func map<U>(_ transform: @escaping (OutputType) -> U ) -> RLS.Map<Self, U>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) -> T ) -> RLS.Reduce<Self, T>
}

public protocol ReallyLazySequence {
    
}

public extension Composable {
    public func map<T>(_ transform: @escaping (OutputType) -> T ) -> RLS.Map<Self, T> {
        return RLS.Map<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((OutputType?) -> Continuation) in
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { return { delivery(nil) } }
                return { delivery(transform(input)) }
            }
        }
    }

    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) -> T ) -> RLS.Reduce<Self, T> {
        return RLS.Reduce<Self, T>(predecessor: self) { (delivery: @escaping (T?) -> Continuation) -> ((OutputType?) -> Continuation) in
            var partialValue = initialValue
            return { (input: OutputType?) -> Continuation in
                guard let input = input else { partialValue = initialValue; return deliver(values: [partialValue], delivery: delivery) }
                return { partialValue = combine(partialValue, input); return nil }
            }
        }
    }
}

public protocol ChainedComposable: Composable {
    associatedtype PredecessorType: Composable
    typealias Composer = (@escaping (OutputType?) -> Continuation) -> ((PredecessorType.OutputType?) -> Continuation)
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
}

public extension ChainedComposable {
    public func compose(_ output: @escaping (OutputType?) -> Continuation) -> ((PredecessorType.HeadType?) -> Continuation) {
        let composition = self.composer(output)
        return predecessor.compose(composition)
    }
}

public struct RLS {
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

    public struct Reduce<Predecessor: Composable, Output>: ChainedComposable {
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
