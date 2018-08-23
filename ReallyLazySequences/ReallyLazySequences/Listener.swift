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
    func listener() -> ListenableSequence<Self, ListenableType>
    func hasListeners() -> Bool
    func add(listener: Consumer<ListenableType>)
    func remove(listener: Consumer<ListenableType>)
    func remove(proxy: ListenerProxy<Self>) -> Consumer<ListenableType>?
}

extension Listenable {
    public func hasListeners() -> Bool { return listeners.count > 0 }
    
    public func add(listener: Consumer<ListenableType>) {
        listeners[listener.identifier] = listener
    }
    
    public func remove(listener: Consumer<ListenableType>) {
        listeners.removeValue(forKey: listener.identifier)
    }
    
    public func remove(proxy: ListenerProxy<Self>) -> Consumer<ListenableType>? {
        let c = listeners[proxy.identifier]
        listeners.removeValue(forKey: proxy.identifier)
        return c
    }
    
    public func listener() -> ListenableSequence<Self, ListenableType> {
        return ListenableSequence<Self, ListenableType>(self) { (listener: Consumer<ListenableType>) in
            self.add(listener: listener)
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

public protocol ListenableSequenceProtocol: ReallyLazySequenceProtocol {
    associatedtype HeadType: Listenable
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

public struct ListenableSequence<T, U>: ListenableSequenceProtocol where T: Listenable {
    public typealias InputType = U
    public typealias OutputType = U
    public typealias HeadType = T
    
    public var description: String = "ListenableSequence<\(type(of:T.self), type(of:U.self))>"
        .replacingOccurrences(of: ".Type", with: "").replacingOccurrences(of: "Swift.", with: "")

    public var compositionHandler: (Consumer<U>) -> Void
    private weak var head: HeadType?
    private var identifier = UUID()
    
    init(_ head: T, compositionHandler: @escaping (Consumer<U>) -> Void) {
        self.head = head
        self.compositionHandler = compositionHandler
    }
    
    public func proxy() -> ListenerProxy<T> {
        return ListenerProxy(identifier: identifier, listenable: head)
    }
    
    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery {
        let listener = Consumer<U>(delivery: delivery)
        compositionHandler(listener)
        return { _ in throw ReallyLazySequenceError.nonPushable }
    }
    
    public func listen(_ delivery: @escaping (U?) -> Void) -> ListenerProxy<T> {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in
            delivery(value)
            return .done
        }
        let _ = compose(deliveryWrapper)
        return ListenerProxy(identifier: identifier, listenable: head)
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

public protocol ListenableGeneratorProtocol: Listenable {
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
    public var listeners: [UUID : Consumer<U>] = [ : ]
    public typealias InputType = T
    public typealias ListenableType = U
    public var generator: (T, @escaping (U?) -> Void) -> Void
    
    public init(_ generator: @escaping (T, @escaping (U?) -> Void) -> Void) {
        self.generator = generator
    }
}
