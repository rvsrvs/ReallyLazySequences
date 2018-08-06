//
//  Listener.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/5/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public enum ListenerResult {
    case `continue`
    case terminate
    case error
}

public protocol Listenable {
    associatedtype ValueType
    func listenable() -> ListenerComposer<ValueType>
}

public protocol ListenerProtocol {
    associatedtype InputType
    var identifier: UUID { get }
    func push(_ value: InputType) throws -> ListenerResult
}

public struct Listener<T>: ListenerProtocol, Equatable {
    
    public static func == (lhs: Listener<T>, rhs: Listener<T>) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public typealias InputType = T
    private(set) public var identifier = UUID()
    
    var delivery: (InputType?) -> Continuation
    
    init(delivery: @escaping (InputType?) -> Continuation) {
        self.delivery = delivery
    }
    
    public func push(_ value: T) throws -> ListenerResult {
        return .terminate
    }
}

public struct ListenerComposer<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    
    public var compositionHandler: (Listener<T>) -> Void
    
    init(compositionHandler: @escaping (Listener<T>) -> Void) {
        self.compositionHandler = compositionHandler
    }

    public func compose(_ output: @escaping (T?) -> Continuation) -> (T?) throws -> Void {
        let listener = Listener<T>(delivery: output)
        compositionHandler(listener)
        return { _ in throw ReallyLazySequenceError.nonPushable }
    }
}

public class ListenableValue<T>: Listenable {
    public typealias ValueType = T
    
    private var listeners = [UUID: Listener<T>]()
    var value: T {
        didSet {
            listeners.values.forEach { listener in
                do {
                    if try listener.push(value) == .terminate {
                        remove(listener: listener)
                    }
                } catch {
                    remove(listener: listener)
                }
            }
        }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    private func add(listener: Listener<T>) {
        listeners[listener.identifier] = listener
    }
    
    private func remove(listener: Listener<T>) {
        listeners.removeValue(forKey: listener.identifier)
    }
    
    public func listenable() -> ListenerComposer<T> {
        return ListenerComposer<T> { (listener: Listener<T>) in
            self.add(listener: listener)
        }
    }
}
