//
//  Listener.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/5/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public protocol Listenable {
    associatedtype ListenableType
    associatedtype ListenableSequenceType: ListenableSequenceProtocol where ListenableSequenceType.InputType == ListenableType
    func listener() -> ListenableSequenceType
}

public protocol ListenerManagerProtocol: class, Listenable {
    var listeners: [UUID: Listener<ListenableType, Self>] { get set }
    func hasListeners() -> Bool
    func add(listener: Listener<ListenableType, Self>)
    func remove(listener: Listener<ListenableType, Self>)
    func remove(_ proxy: ListenerProxy<Self>)
}

extension ListenerManagerProtocol {
    public func hasListeners() -> Bool { return listeners.count > 0 }
    
    public func add(listener: Listener<ListenableType, Self>) {
        listeners[listener.identifier] = listener
    }
    
    public func remove(listener: Listener<ListenableType, Self>) {
        listeners.removeValue(forKey: listener.identifier)
    }
    
    public func remove(_ proxy: ListenerProxy<Self>) {
        listeners.removeValue(forKey: proxy.identifier)
    }
    
    public func listener() -> ListenableSequence<ListenableType, Self> {
        return ListenableSequence<ListenableType, Self>(self) { (listener: Listener<ListenableType, Self>) in
            self.add(listener: listener)
        }
    }
}

public struct ListenerProxy<T> where T: ListenerManagerProtocol {
    var identifier: UUID
    var listenerManager: T?
    
    public mutating func terminate() {
        guard let lm = listenerManager else { return }
        lm.remove(self)
        listenerManager = nil
    }
}

public protocol ListenerProtocol {
    associatedtype InputType
    var identifier: UUID { get }
    func process(_ value: InputType?) throws -> ContinuationResult
    func terminate() -> ContinuationResult
}

public struct Listener<T, U>: ListenerProtocol, Equatable where U: ListenerManagerProtocol {
    public static func == (lhs: Listener<T, U>, rhs: Listener<T, U>) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public typealias InputType = T
    private(set) public var identifier: UUID
    
    weak var head: U?
    var delivery: (InputType?) -> ContinuationResult
    
    init(_ head: U, _ identifier: UUID, delivery: @escaping (InputType?) -> ContinuationResult) {
        self.head = head
        self.identifier = identifier
        self.delivery = delivery
    }
    
    public func process(_ value: T?) throws -> ContinuationResult {
        return ContinuationResult.complete(delivery(value))
    }
    
    public func terminate() -> ContinuationResult {
        return ContinuationResult.complete(delivery(nil))
    }
}

public protocol ListenableSequenceProtocol: ReallyLazySequenceProtocol {
    associatedtype HeadType: ListenerManagerProtocol
    func listen(_ delivery: @escaping (OutputType?) -> Void) -> ListenerProxy<HeadType>
    func proxy() -> ListenerProxy<HeadType>
    func dispatch(_ queue: OperationQueue) -> ListenableDispatch<Self, OutputType>
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ListenableReduce<Self, T>
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ListenableMap<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ListenableCompactMap<Self, T>
    func flatMap<T, U>(queue: OperationQueue?, _ transform: @escaping (OutputType) throws -> U) -> ListenableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
    func flatMap<T, U>(_ transform: @escaping (OutputType) throws -> U) -> ListenableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ListenableReduce<Self, T>
    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ListenableFilter<Self, OutputType>
}

public struct ListenableSequence<T, U>: ListenableSequenceProtocol where U: ListenerManagerProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    public typealias HeadType = U
    
    public var compositionHandler: (Listener<T, U>) -> Void
    private weak var head: HeadType?
    private var identifier = UUID()
    
    init(_ head: U, compositionHandler: @escaping (Listener<T, U>) -> Void) {
        self.head = head
        self.compositionHandler = compositionHandler
    }
    
    public func proxy() -> ListenerProxy<U> {
        return ListenerProxy(identifier: identifier, listenerManager: head)
    }
    
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery {
        guard let head = head else { return { _ in .done } }
        let listener = Listener<T, U>(head, identifier, delivery: delivery)
        compositionHandler(listener)
        return { _ in throw ReallyLazySequenceError.nonPushable }
    }
    
    public func listen(_ delivery: @escaping (T?) -> Void) -> ListenerProxy<U> {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in
            delivery(value)
            return .done
        }
        let _ = compose(deliveryWrapper)
        return ListenerProxy(identifier: identifier, listenerManager: head)
    }
}

public protocol ListenableChainedSequence: ListenableSequenceProtocol where HeadType == PredecessorType.HeadType {
    associatedtype PredecessorType: ListenableSequenceProtocol
    typealias PredecessorContinuableOutputDelivery = (PredecessorType.OutputType?) -> ContinuationResult
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorContinuableOutputDelivery
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

public protocol ListenableGeneratorProtocol: ListenerManagerProtocol {
    associatedtype InputType
    var generator: (InputType, @escaping (ListenableType?) -> Void) -> Void { get set }
    init(_ generator: @escaping (InputType, @escaping (ListenableType?) -> Void) -> Void)
    func generate(for: InputType) -> Void
}

extension ListenableGeneratorProtocol {
    public func generate(for value: InputType) {
        let delivery = { (input: ListenableType?) -> Void in
            guard self.hasListeners() else { return }
            self.listeners.forEach { (pair) in
                let (_, listener) = pair
                do {
                    _ = try listener.process(input)
                } catch {
                    self.remove(listener: listener)
                }
            }
        }
        generator(value, delivery)
    }
}

public final class ListenableGenerator<T, U>: ListenableGeneratorProtocol {
    public var listeners: [UUID : Listener<U, ListenableGenerator<T, U>>] = [ : ]
    public typealias InputType = T
    public typealias ListenableType = U
    public typealias ListenableSequenceType = ListenableSequence<ListenableType, ListenableGenerator<T,U>>
    public var generator: (T, @escaping (U?) -> Void) -> Void
    
    public init(_ generator: @escaping (T, @escaping (U?) -> Void) -> Void) {
        self.generator = generator
    }
}
