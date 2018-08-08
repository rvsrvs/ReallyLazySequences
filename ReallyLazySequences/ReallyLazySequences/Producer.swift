//
//  Producer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public protocol ProducerProtocol: class, Listenable {
    var hasListeners: Bool { get }
    func produce() throws
    init(producer: @escaping ((ListenableType) -> Void, () -> Void) -> Void)
}

public final class Producer<T>: ProducerProtocol {
    public typealias ListenableType = T
    public typealias ListenableSequenceType = ListenableSequence<T>
    
    fileprivate(set) public var listeners = [UUID: Listener<T>]()
    
    public var hasListeners: Bool { return listeners.count > 0 }
    
    private var producer: ((T) -> Void, () -> Void) -> Void
    
    public init(producer: @escaping ((T) -> Void, () -> Void) -> Void) {
        self.producer = producer
    }

    public func produce() throws {
        guard hasListeners else { throw ReallyLazySequenceError.noListeners }
        producer(push, terminate)
    }
    
    private func push(_ value: T) {
        listeners.values.forEach { listener in
            do { try listener.push(value) }
            catch { remove(listener: listener) }
        }
    }
    
    private func terminate() {
        listeners.values.forEach { listener in
            listener.terminate()
            remove(listener: listener)
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
