//
//  Value.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/8/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public class ListenableValue<T>: ListenerManagerProtocol {
    public typealias ListenableType = T
    public typealias ListenableSequenceType = ListenableSequence<T>
    
    public var listeners = [UUID: Listener<T>]()
    
    var hasListeners: Bool { return listeners.count > 0 }
    
    var value: T {
        didSet { self.push(value) }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    private func push(_ value: T) {
        listeners.values.forEach { listener in
            do {
                _ = try listener.process(value)
            }
            catch { remove(listener: listener) }
        }
    }
    
    func terminate() {
        listeners.values.forEach { listener in
            _ = listener.terminate()
            remove(listener: listener)
        }
    }
}
