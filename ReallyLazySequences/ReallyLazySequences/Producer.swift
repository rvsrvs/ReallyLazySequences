//
//  Producer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

public protocol TaskProtocol {
    var isStarted: Bool { get }
    var isCompleted: Bool { get }
    func start() throws -> Void
}

public struct Producer<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    public typealias ProducerConsumer = Consumer<Producer<T>>
    
    public class Task: TaskProtocol {
        private(set) public var isStarted = false
        private(set) public var isCompleted = false
        private var consumer: ProducerConsumer!
        
        init(_ producer: Producer<T>, _ delivery: @escaping OutputFunction) {
            let composedDelivery = { (value: OutputType?) -> Continuation in
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
    
    public init(_ produce:  @escaping ((T?) -> Void) throws -> Void) {
        self.produce = produce
    }
    
    public func compose(_ output: (@escaping (T?) -> Continuation)) -> ((T?) throws -> Void) {
        var completed = false
        return { (value: T?) throws -> Void in
            guard value == nil else { throw ReallyLazySequenceError.nonPushable }
            guard !completed else { throw ReallyLazySequenceError.isComplete }
            completed = true
            try self.produce { drive(output($0)) }
        }
    }
    
    public func task(_ delivery: @escaping OutputFunction) -> TaskProtocol {
        return Task(self, delivery)
    }
}
