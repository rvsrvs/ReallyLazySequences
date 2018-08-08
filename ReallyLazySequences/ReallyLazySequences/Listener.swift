//
//  Listener.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/5/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public enum ListenerResult {
    case `continue`
    case terminate
    case error
}

public protocol Listenable {
    associatedtype ListenableType
    associatedtype ListenableSequenceType: ReallyLazySequenceProtocol where ListenableSequenceType.InputType == ListenableType
    func listener() -> ListenableSequenceType
}

public protocol ListenerProtocol {
    associatedtype InputType
    var identifier: UUID { get }
    func push(_ value: InputType) throws -> ListenerResult
}

public struct Listener<T>: ListenerProtocol, Equatable {
    public static func == (lhs: Listener<T>, rhs: Listener<T>) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public typealias InputType = T
    private(set) public var identifier = UUID()
    
    var delivery: (InputType?) -> Continuation
    
    init(delivery: @escaping (InputType?) -> Continuation) {
        self.delivery = delivery
    }
    
    public func push(_ value: T) throws -> ListenerResult {
        drive(delivery(value))
        return .continue
    }
}

public struct ListenableSequence<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    
    public var compositionHandler: (Listener<T>) -> Void
    
    init(compositionHandler: @escaping (Listener<T>) -> Void) {
        self.compositionHandler = compositionHandler
    }

    public func compose(_ output: @escaping ContinuableOutputDelivery) -> (T?) throws -> Void {
        let listener = Listener<T>(delivery: output)
        compositionHandler(listener)
        return { _ in throw ReallyLazySequenceError.nonPushable }
    }
}

public class ListenableValue<T>: Listenable {
    public typealias ListenableType = T
    public typealias ListenableSequenceType = ListenableSequence<T>

    fileprivate var listeners = [UUID: Listener<T>]()
    
    var hasListeners: Bool { return listeners.count > 0 }
    
    var value: T {
        willSet { self.push(newValue) }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    private func push(_ value: T) {
        listeners.values.forEach { listener in
            do { if try listener.push(value) == .terminate { remove(listener: listener) } }
            catch { remove(listener: listener) }
        }
    }
    
    private func add(listener: Listener<T>) {
        listeners[listener.identifier] = listener
    }
    
    private func remove(listener: Listener<T>) {
        listeners.removeValue(forKey: listener.identifier)
    }
    
    public func listener() -> ListenableSequence<T> {
        return ListenableSequence<T> { (listener: Listener<T>) in
            self.add(listener: listener)
        }
    }
}

public protocol ValueProducer {
    associatedtype ProducedType
    var value: ListenableValue<ProducedType> { get }
    func produce() throws
}

public struct ListenableProducer<T>: Listenable {
    public typealias ListenableType = T
    public typealias ListenableSequenceType = ListenableSequence<T>
    var value: ListenableValue<T>
    var producer: (ListenableValue<T>) -> Void
    
    public init(initialValue: T, produceWith producer: @escaping (ListenableValue<T>) -> Void) {
        self.value = ListenableValue<T>(initialValue)
        self.producer = producer
    }
    
    public func produce() throws {
        guard value.listeners.count > 0 else { throw ReallyLazySequenceError.noListeners }
        producer(value)
    }
    
    public func listener() -> ListenableSequence<T> {
        return value.listener()
    }
}
