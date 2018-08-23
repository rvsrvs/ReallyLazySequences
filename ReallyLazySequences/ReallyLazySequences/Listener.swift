//
//  Listener.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/5/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public protocol Listenable: class {
    associatedtype ListenableType
    var listeners: [UUID: Consumer<ListenableType>] { get set }
    func listener() -> Listener<Self, ListenableType>
    var hasListeners: Bool { get }
    func add(_ consumer: Consumer<ListenableType>) -> ListenerProxy<Self>
    func remove(consumer: Consumer<ListenableType>) -> Consumer<ListenableType>?
    func remove(proxy: ListenerProxy<Self>) -> Consumer<ListenableType>?
    func terminate()
}

extension Listenable {
    public var hasListeners: Bool { return listeners.count > 0 }
    
    public func add(_ consumer: Consumer<ListenableType>)  -> ListenerProxy<Self> {
        let uuid = UUID()
        listeners[uuid] = consumer
        return ListenerProxy<Self>(identifier: uuid, listenable: self)
    }
    
    public func remove(consumer: Consumer<ListenableType>) -> Consumer<ListenableType>? {
        let c = listeners[consumer.identifier]
        listeners.removeValue(forKey: consumer.identifier)
        return c
    }
    
    public func remove(proxy: ListenerProxy<Self>) -> Consumer<ListenableType>? {
        let c = listeners[proxy.identifier]
        listeners.removeValue(forKey: proxy.identifier)
        return c
    }
    
    
    public func terminate() {
        listeners.values.forEach { listener in
            _ = try? listener.process(nil)
            _ = remove(consumer: listener)
        }
    }

    public func listener() -> Listener<Self, ListenableType> {
        return Listener<Self, ListenableType>(self) { (consumer: Consumer<ListenableType>) in
            _ = self.add(consumer)
        }
    }
}

public struct ListenerProxy<T> where T: Listenable {
    var identifier: UUID
    var listenable: T?
    
    public mutating func terminate() {
        guard let l = listenable else { return }
        let c = l.remove(proxy:self)
        _ = try? c?.process(nil)
        listenable = nil
    }
}

public protocol ListenerProtocol: ReallyLazySequenceProtocol {
    associatedtype ListenableType: Listenable
    func listen(_ delivery: @escaping (OutputType?) -> ContinuationTermination) -> ListenerProxy<ListenableType>
    func proxy() -> ListenerProxy<ListenableType>
    
    // Listenable Chaining
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

public struct Listener<T, U>: ListenerProtocol where T: Listenable {
    public typealias ListenableType = T
    public typealias InputType = U
    public typealias OutputType = U
    
    public var description: String = "Listener<\(type(of:T.self), type(of:U.self))>"
        .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")

    public var installer: (Consumer<U>) -> Void
    private weak var listenable: ListenableType?
    private var identifier = UUID()
    
    init(_ listenable: T, installer: @escaping (Consumer<U>) -> Void) {
        self.listenable = listenable
        self.installer = installer
    }
    
    public func proxy() -> ListenerProxy<T> {
        return ListenerProxy(identifier: identifier, listenable: listenable)
    }
    
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery {
        let listener = Consumer<U>(delivery: delivery)
        installer(listener)
        return { _ in throw ReallyLazySequenceError.nonPushable }
    }
    
    public func listen(_ delivery: @escaping (U?) -> ContinuationTermination) -> ListenerProxy<T> {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in return .done(delivery(value)) }
        let _ = compose(deliveryWrapper)
        return ListenerProxy(identifier: identifier, listenable: listenable)
    }
}

public protocol ChainedListenerProtocol: ListenerProtocol where ListenableType == PredecessorType.ListenableType {
    associatedtype PredecessorType: ListenerProtocol
    typealias PredecessorContinuableOutputDelivery = (PredecessorType.OutputType?) -> ContinuationResult
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorContinuableOutputDelivery
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

public protocol ListenableSequenceProtocol: Listenable {
    associatedtype InputType
    var sequenceGenerator: (InputType, @escaping (ListenableType?) -> Void) -> Void { get set }
    init(_ generator: @escaping (InputType, @escaping (ListenableType?) -> Void) -> Void)
    func generate(for: InputType) -> Void
}

extension ListenableSequenceProtocol {
    public func generate(for value: InputType) {
        let delivery = { (input: ListenableType?) -> Void in
            guard self.hasListeners else { return }
            self.listeners.forEach { (pair) in
                let (identifier, listener) = pair
                do { _ = try listener.process(input) }
                catch { self.listeners.removeValue(forKey: identifier) }
            }
        }
        sequenceGenerator(value, delivery)
    }
}

public final class ListenableSequence<T, U>: ListenableSequenceProtocol {
    public var listeners: [UUID : Consumer<U>] = [ : ]
    public typealias InputType = T
    public typealias ListenableType = U
    public var sequenceGenerator: (T, @escaping (U?) -> Void) -> Void
    
    public init(_ sequenceGenerator: @escaping (T, @escaping (U?) -> Void) -> Void) {
        self.sequenceGenerator = sequenceGenerator
    }
}
