//
//  Listener.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/5/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public protocol ListenableSequenceProtocol: ReallyLazySequenceProtocol {
    func listen(_ delivery: @escaping (OutputType?) -> Void)
    func dispatch(_ queue: OperationQueue) -> ListenableDispatch<Self, OutputType>
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
        ) -> ListenableReduce<Self, T>
    func flatMap<T, U>(queue: OperationQueue?, _ transform: @escaping (OutputType) throws -> U) -> ListenableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ListenableMap<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ListenableCompactMap<Self, T>
    func flatMap<T, U>(_ transform: @escaping (OutputType) throws -> U) -> ListenableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ListenableReduce<Self, T>
    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ListenableFilter<Self, OutputType>
}

public protocol ListenableChainedSequence: ListenableSequenceProtocol {
    associatedtype PredecessorType: ListenableSequenceProtocol
    typealias PredecessorContinuableOutputDelivery = (PredecessorType.OutputType?) -> ContinuationResult
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorContinuableOutputDelivery
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

public protocol Listenable {
    associatedtype ListenableType
    associatedtype ListenableSequenceType: ListenableSequenceProtocol where ListenableSequenceType.InputType == ListenableType
    func listener() -> ListenableSequenceType
}

public protocol ListenerProtocol {
    associatedtype InputType
    var identifier: UUID { get }
    func push(_ value: InputType) throws
    func terminate()
}

public struct Listener<T>: ListenerProtocol, Equatable {
    public static func == (lhs: Listener<T>, rhs: Listener<T>) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public typealias InputType = T
    private(set) public var identifier = UUID()
    
    var delivery: (InputType?) -> ContinuationResult
    
    init(delivery: @escaping (InputType?) -> ContinuationResult) {
        self.delivery = delivery
    }
    
    public func push(_ value: T) throws {
        _ = ContinuationResult.complete(delivery(value))
    }
    
    public func terminate() {
        _ = ContinuationResult.complete(delivery(nil))
    }
}

public struct ListenableSequence<T>: ListenableSequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    
    public var compositionHandler: (Listener<T>) -> Void
    
    init(compositionHandler: @escaping (Listener<T>) -> Void) {
        self.compositionHandler = compositionHandler
    }

    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery {
        let listener = Listener<T>(delivery: delivery)
        compositionHandler(listener)
        return { _ in throw ReallyLazySequenceError.nonPushable }
    }
    
    public func listen(_ delivery: @escaping (OutputType?) -> Void) {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in
            delivery(value)
            return .done
        }
        let _ = compose(deliveryWrapper)
    }
}

public protocol ListenerManagerProtocol: class, Listenable {
    var listeners: [UUID: Listener<ListenableType>] { get set }
    
    func hasListeners() -> Bool
    func add(listener: Listener<ListenableType>)
    func remove(listener: Listener<ListenableType>)
}

extension ListenerManagerProtocol {
    public func hasListeners() -> Bool { return listeners.count > 0 }
    
    public func add(listener: Listener<ListenableType>) {
        listeners[listener.identifier] = listener
    }
    
    public func remove(listener: Listener<ListenableType>) {
        listeners.removeValue(forKey: listener.identifier)
    }
    
    public func listener() -> ListenableSequence<ListenableType> {
        return ListenableSequence<ListenableType> { (listener: Listener<ListenableType>) in
            self.add(listener: listener)
        }
    }
}

public protocol ListenableGeneratorProtocol: ListenerManagerProtocol {
    var generator: (@escaping (ListenableType?) -> Void) -> Void { get }
    init(generator: @escaping ((ListenableType?) -> Void) -> Void)
    func generate() throws
}

extension ListenableGeneratorProtocol {
    public func generate() throws {
        guard hasListeners() else { throw ReallyLazySequenceError.noListeners }
        let push = { (value: ListenableType?) in
            guard let value = value else {
                self.listeners.values.forEach { listener in
                    listener.terminate()
                    self.remove(listener: listener)
                }
                return
            }
            self.listeners.values.forEach { listener in
                do { try listener.push(value) }
                catch { self.remove(listener: listener) }
            }
        }
        generator(push)
    }
}

public final class ListenableGenerator<T>: ListenableGeneratorProtocol {
    public typealias ListenableType = T
    public typealias ListenableSequenceType = ListenableSequence<T>
    
    public var listeners = [UUID: Listener<T>]()
    public var generator: (@escaping (T?) -> Void) -> Void
    
    public init(generator: @escaping ((T?) -> Void) -> Void) {
        self.generator = generator
    }
}

