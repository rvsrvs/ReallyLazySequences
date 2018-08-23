//
//  Value.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/8/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public final class ListenableValue<T>: Listenable {
    public typealias ListenableType = T
    
    public var listeners = [UUID: Consumer<T>]()
    
    var hasListeners: Bool { return listeners.count > 0 }
    
    var value: T {
        didSet {
            listeners.values.forEach { listener in
                do { _ = try listener.process(value) }
                catch { _ = remove(consumer: listener) }
            }
        }
    }
    
    init(_ value: T) {
        self.value = value
    }
}
