//
//  Producer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public protocol TaskProtocol {
    var isStarted: Bool { get }
    var isCompleted: Bool { get }
    func start() throws -> Void
}

public class ListenableProducer<T>: Listenable {
    
    private var listeners = [UUID: Listener<T>]()

    public var produce: (@escaping (T?) -> Void) throws -> Void

    public init(_ produce:  @escaping (@escaping (T?) -> Void) throws -> Void) {
        self.produce = produce
    }

    private func notifyListeners(value: T?)  {
        listeners.values.forEach { listener in
            guard let value = value else { remove(listener: listener); return }
            do {
                if try listener.push(value) == .terminate { remove(listener: listener) }
            } catch {
                remove(listener: listener)
            }
        }
    }

    public func start() throws {
        do {
            try self.produce(notifyListeners(value:))
        } catch {
            throw error
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

public struct Producer<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    public typealias ProducerConsumer = Consumer<Producer<T>>
    
    public class Task: TaskProtocol {
        private(set) public var isStarted = false
        private(set) public var isCompleted = false
        private var consumer: ProducerConsumer!
        
        init(_ producer: Producer<T>, _ delivery: @escaping ConsumerFunction) {
            let composedDelivery = { (value: OutputType?) -> Void in
                if value == nil { self.isCompleted = true }
                return delivery(value)
            }
            self.consumer = producer.consume(composedDelivery)
        }
        
        public func start() throws -> Void {
            guard !isStarted else { throw ReallyLazySequenceError.nonPushable }
            isStarted = true
            try consumer.push(nil)
        }
    }
    
    public var produce: (@escaping (T?) -> Void) throws -> Void
    
    public init(_ produce:  @escaping (@escaping (T?) -> Void) throws -> Void) {
        self.produce = produce
    }
    
    public func compose(_ output: (@escaping (T?) -> Continuation)) -> ((T?) throws -> Void) {
        var completed = false
        return { value in
            guard value == nil else { throw ReallyLazySequenceError.nonPushable }
            guard !completed else { throw ReallyLazySequenceError.isComplete }
            try self.produce { drive(output($0)) }
            completed = true
        }
    }
    
    public func task(_ delivery: @escaping ConsumerFunction) -> TaskProtocol {
        return Task(self, delivery)
    }
}
