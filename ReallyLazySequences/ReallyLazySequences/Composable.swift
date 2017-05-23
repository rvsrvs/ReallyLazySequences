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
    func compose(_ output: @escaping (OutputType?) -> Any) -> ((HeadType?) -> Any)
    func map<U>(_ transform: @escaping (OutputType) -> U ) -> Chained<Self, U>
}

public extension Composable {
    public func map<U>(_ transform: @escaping (OutputType) -> U ) -> Chained<Self, U> {
        return Chained<Self, U>(predecessor: self) { (delivery: @escaping (U?) -> Any) -> ((OutputType?) -> Any) in
            func accept(input: OutputType?) -> Any {
                guard let input = input else { return { delivery(nil) } }
                return { delivery(transform(input)) }
            }
            return accept
        }
    }
}

public struct Chained<Predecessor: Composable, Output> {
    public typealias HeadType = Predecessor.HeadType
    public typealias OutputType = Output
    public typealias PredecessorType = Predecessor
    
    typealias Composer = (@escaping (OutputType?) -> Any) -> ((Predecessor.OutputType?) -> Any)
    public var predecessor: Predecessor
    var composer: Composer
    
    init(predecessor: Predecessor, composer: @escaping Composer) {
        self.predecessor = predecessor
        self.composer = composer
    }
    
    public func compose(_ output: @escaping (Output?) -> Any) -> ((Predecessor.HeadType?) -> Any) {
        let composition = self.composer(output)
        return predecessor.compose(composition)
    }
}
