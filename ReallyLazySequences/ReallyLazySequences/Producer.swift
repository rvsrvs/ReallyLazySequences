//
//  Producer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 7/31/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//
import Foundation

public struct Producer<T>: Listenable {
    public typealias ListenableType = T
    public typealias ListenableSequenceType = ListenableSequence<T>
    var value: ListenableValue<T>
    var producer: (ListenableValue<T>) -> Void
    
    public init(initialValue: T, produceWith producer: @escaping (ListenableValue<T>) -> Void) {
        self.value = ListenableValue<T>(initialValue)
        self.producer = producer
    }
    
    public func produce() throws {
        guard value.hasListeners else { throw ReallyLazySequenceError.noListeners }
        producer(value)
    }
    
    public func listener() -> ListenableSequence<T> {
        return value.listener()
    }
}
