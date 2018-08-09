//
//  Producer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public protocol ProducerProtocol: class, Listenable {
    var listeners: [UUID: Listener<ListenableType>] { get set }
    var producer: (@escaping (ListenableType?) -> Void) -> Void { get }
    
    init(producer: @escaping ((ListenableType?) -> Void) -> Void)

    func produce() throws
    func hasListeners() -> Bool
    func add(listener: Listener<ListenableType>)
    func remove(listener: Listener<ListenableType>)
}

extension ProducerProtocol {
    public func produce() throws {
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
        producer(push)
    }
    
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

public final class Producer<T>: ProducerProtocol {
    public typealias ListenableType = T
    public typealias ListenableSequenceType = ListenableSequence<T>
    
    public var listeners = [UUID: Listener<T>]()
    public var producer: (@escaping (T?) -> Void) -> Void

    public init(producer: @escaping ((T?) -> Void) -> Void) {
        self.producer = producer
    }
}
