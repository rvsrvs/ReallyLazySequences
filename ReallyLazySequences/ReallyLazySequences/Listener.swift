//
//  Listener.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/5/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

public protocol Listenable {
    associatedtype ListenableType
    associatedtype ListenableSequenceType: ReallyLazySequenceProtocol where ListenableSequenceType.InputType == ListenableType
    func listener() -> ListenableSequenceType
}

public protocol ListenerProtocol {
    associatedtype InputType
    var identifier: UUID { get }
    func push(_ value: InputType) throws
    func terminate()
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
    
    public func push(_ value: T) throws {
        drive(delivery(value))
    }
    
    public func terminate() {
        drive(delivery(nil))
    }
}

public struct ListenableSequence<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    
    public var compositionHandler: (Listener<T>) -> Void
    
    init(compositionHandler: @escaping (Listener<T>) -> Void) {
        self.compositionHandler = compositionHandler
    }

    public func compose(_ output: @escaping ContinuableOutputDelivery) -> (T?) throws -> Void {
        let listener = Listener<T>(delivery: output)
        compositionHandler(listener)
        return { _ in throw ReallyLazySequenceError.nonPushable }
    }
    
    public func listen(_ delivery: @escaping (OutputType?) -> Void) {
        let deliveryWrapper = { (value: OutputType?) -> Continuation in
            delivery(value)
            return ContinuationDone
        }
        let _ = compose(deliveryWrapper)
    }
}

