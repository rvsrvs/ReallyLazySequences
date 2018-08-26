//
//  Value.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/8/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public final class ListenableValue<T>: Listenable {
    public var description: String
    
    public typealias ListenableOutputType = T
    
    public var listeners = [UUID: Consumer<T>]()
    public var hasListeners: Bool { return listeners.count > 0 }
    
    var value: T {
        didSet {
            listeners.keys.forEach { uuid in
                do { _ = try listeners[uuid]?.process(value) }
                catch { _ = remove(listenerWith: uuid) }
            }
        }
    }
    
    init(_ value: T) {
        self.description = standardize("ListenableValue<\(type(of: T.self))>")
        self.value = value
    }
}
