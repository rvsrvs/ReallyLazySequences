//
//  Value.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/8/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public final class ListenableValue<T>: ListenerManagerProtocol {
    public typealias ListenableType = T
    public typealias ListenableSequenceType = ListenableSequence<T, ListenableValue<T>>
    
    public var listeners = [UUID: Listener<T, ListenableValue<T>>]()
    
    var hasListeners: Bool { return listeners.count > 0 }
    
    var value: T {
        didSet {
            listeners.values.forEach { listener in
                do { _ = try listener.process(value) }
                catch { remove(listener: listener) }
            }
        }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    func terminate() {
        listeners.values.forEach { listener in
            _ = listener.terminate()
            remove(listener: listener)
        }
    }
}
