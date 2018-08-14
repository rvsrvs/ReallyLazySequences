//
//  Value.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/8/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public class ListenableValue<T>: Listenable {
    public typealias ListenableType = T
    public typealias ListenableSequenceType = ListenableSequence<T>
    
    fileprivate var listeners = [UUID: Listener<T>]()
    
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
                try listener.push(value)
            }
            catch { remove(listener: listener) }
        }
    }
    
    func terminate() {
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
