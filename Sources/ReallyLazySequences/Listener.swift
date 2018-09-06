//
//  Listener.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/5/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public protocol Listenable: class, CustomStringConvertible {
    associatedtype ListenableOutputType

    var listeners: [UUID: Consumer<ListenableOutputType>] { get set }
    var hasListeners: Bool { get }

    func listener() -> Listener<Self>
    func add(listener: Consumer<ListenableOutputType>, with: UUID)
    func remove(listenerWith: UUID) -> Consumer<ListenableOutputType>?
    func terminate()
}

extension Listenable {
    public var hasListeners: Bool { return listeners.count > 0 }
    
    public func add(listener: Consumer<ListenableOutputType>, with uuid: UUID) {
        listeners[uuid] = listener
    }
    
    public func remove(listenerWith: UUID) -> Consumer<ListenableOutputType>? {
        return listeners.removeValue(forKey: listenerWith)
    }
    
    public func terminate() {
        listeners.keys.forEach { uuid in
            _ = try? listeners[uuid]?.process(nil)
            _ = remove(listenerWith: uuid)
        }
    }

    public func listener() -> Listener<Self> {
        return Listener<Self>(self) { (uuid: UUID, consumer: Consumer<ListenableOutputType>) in
            self.add(listener: consumer, with: uuid)
        }
    }
}

public struct ListenerHandle<T>: CustomStringConvertible where T: Listenable {
    public var description: String
    
    var identifier: UUID
    var listenable: T?
    
    public init(identifier: UUID, listenable: T?) {
        self.identifier = identifier
        self.listenable = listenable
        self.description = standardizeRLSDescription("\(listenable?.description ?? "nil")   >> ListenerHandle<identifier = \"\(identifier)>\"")
    }
    
    public mutating func terminate() -> Consumer<T.ListenableOutputType>? {
        guard let m = listenable else { return nil }
        let c = m.remove(listenerWith: identifier)
        listenable = nil
        return c
    }
}

public protocol ListenerProtocol: ReallyLazySequenceProtocol {
    associatedtype ListenableType: Listenable
    func listen(_ delivery: @escaping (OutputType?) -> ContinuationTermination) -> ListenerHandle<Self.ListenableType>
    func proxy() -> ListenerHandle<Self.ListenableType>
    
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ListenableMap<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ListenableCompactMap<Self, T>
    func flatMap<T, U>(_ transform: @escaping (OutputType) throws -> U) -> ListenableFlatMap<Self, T>
        where U: SubsequenceProtocol, U.InputType == Self.OutputType, U.OutputType == T

    // Listenable Chaining
    func dispatch(_ queue: OperationQueue) -> ListenableDispatch<Self, OutputType>
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ListenableReduce<Self, T>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ListenableReduce<Self, T>
    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ListenableFilter<Self, OutputType>
}

public struct Listener<T>: ListenerProtocol where T: Listenable {
    public typealias ListenableType = T
    public typealias InputType = T.ListenableOutputType
    public typealias OutputType = T.ListenableOutputType
    
    public var description: String

    public var installer: (UUID, Consumer<T.ListenableOutputType>) -> Void
    private weak var listenable: T?
    private var identifier = UUID()
    
    init(_ listenable: T, installer: @escaping (UUID, Consumer<T.ListenableOutputType>) -> Void) {
        self.listenable = listenable
        self.installer = installer
        self.description = standardizeRLSDescription("\(listenable.description) >> Listener<\(type(of: T.ListenableOutputType.self))>")
    }
    
    public func proxy() -> ListenerHandle<T> {
        return ListenerHandle(identifier: identifier, listenable: listenable)
    }
    
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery? {
        let listener = Consumer<T.ListenableOutputType>(delivery: delivery)
        installer(identifier, listener)
        return nil
    }
    
    public func listen(_ delivery: @escaping (T.ListenableOutputType?) -> ContinuationTermination) -> ListenerHandle<T> {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in return .done(delivery(value)) }
        let _ = compose(deliveryWrapper)
        return ListenerHandle(identifier: identifier, listenable: listenable)
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
    init()
    func process(_ value: ListenableOutputType?) throws -> Void
}

extension ListenableSequenceProtocol {
    public func process(_ value: ListenableOutputType?) throws -> Void {
        guard self.hasListeners else { return }
        self.listeners.forEach { (pair) in
            let (identifier, listener) = pair
            do { _ = try listener.process(value) }
            catch { self.listeners.removeValue(forKey: identifier) }
        }
    }
}

public final class ListenableSequence<T>: ListenableSequenceProtocol {
    public var description: String
    
    public var listeners: [UUID : Consumer<T>] = [ : ]
    public typealias ListenableOutputType = T
    
    public init() {
        self.description = standardizeRLSDescription("ListenableSequence<\(type(of: T.self))>")
    }
}
