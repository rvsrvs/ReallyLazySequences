//
//  Observer.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/5/18.
//

/*
 Copyright 2019, Ronald V. Simmons
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public protocol Observable: class, CustomStringConvertible {
    associatedtype ListenableOutputType

    var observers: [UUID: Consumer<ListenableOutputType>] { get set }
    var hasObservers: Bool { get }
    var observableSequence: ObservableSequence<Self> { get }

    func add(observer: Consumer<ListenableOutputType>, with: UUID)
    func remove(_ observerId: UUID) -> Consumer<ListenableOutputType>?
    func terminate()
}

extension Observable {
    public var hasObservers: Bool { return observers.count > 0 }
    
    public func add(observer: Consumer<ListenableOutputType>, with uuid: UUID) {
        observers[uuid] = observer
    }
    
    public func remove(_ observerId: UUID) -> Consumer<ListenableOutputType>? {
        return observers.removeValue(forKey: observerId)
    }
    
    public func terminate() {
        observers.keys.forEach { uuid in
            _ = ((try? observers[uuid]?.process(nil)) as ContinuationResult??)
            _ = remove(uuid)
        }
    }

    public var observableSequence: ObservableSequence<Self> {
        return ObservableSequence<Self>(self) { (uuid: UUID, consumer: Consumer<ListenableOutputType>) in
            self.add(observer: consumer, with: uuid)
        }
    }
}

public struct ObserverHandle<T>: CustomStringConvertible, Equatable, Hashable where T: Observable {
    public static func == (lhs: ObserverHandle<T>, rhs: ObserverHandle<T>) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public var description: String
    
    var identifier: UUID
    var listenable: T?
    
    public init(identifier: UUID, listenable: T?) {
        self.identifier = identifier
        self.listenable = listenable
        self.description = Utilities.standardizeDescription("\(listenable?.description ?? "nil")   >> ObserverHandle<identifier = \"\(identifier)>\"")
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    public mutating func terminate() -> Consumer<T.ListenableOutputType>? {
        guard let m = listenable else { return nil }
        let c = m.remove(identifier)
        listenable = nil
        return c
    }
}

public protocol ObservableSequenceProtocol: SequenceProtocol {
    associatedtype ListenableType: Observable
    func listen(_ delivery: @escaping (OutputType?) -> ContinuationTermination) -> ObserverHandle<Self.ListenableType>
    func proxy() -> ObserverHandle<Self.ListenableType>
    
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ListenableMap<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ListenableCompactMap<Self, T>
    func flatMap<T>(_ transform: @escaping (OutputType) throws -> Subsequence<OutputType, T>) -> ListenableFlatMap<Self, T> 

    // Listenable Chaining
    func dispatch(_ queue: OperationQueue) -> ListenableDispatch<Self, OutputType>
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ListenableReduce<Self, T>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ListenableReduce<Self, T>
    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ListenableFilter<Self, OutputType>
}

public struct ObservableSequence<T>: ObservableSequenceProtocol where T: Observable {
    public typealias ListenableType = T
    public typealias InputType = T.ListenableOutputType
    public typealias OutputType = T.ListenableOutputType

    public var description: String

    public var installer: (UUID, Consumer<T.ListenableOutputType>) -> Void
    private weak var listenable: T?
    private var identifier = UUID()

    init(_ listenable: T, installer: @escaping (UUID, Consumer<T.ListenableOutputType>) -> Void) {
        self.listenable = listenable
        self.installer = installer
        self.description = Utilities.standardizeDescription("\(listenable.description) >> Observer<\(type(of: T.ListenableOutputType.self))>")
    }

    public func proxy() -> ObserverHandle<T> {
        return ObserverHandle(identifier: identifier, listenable: listenable)
    }

    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery? {
        let consumer = Consumer<T.ListenableOutputType>(delivery: delivery)
        installer(identifier, consumer)
        return nil
    }

    public func listen(_ delivery: @escaping (T.ListenableOutputType?) -> ContinuationTermination) -> ObserverHandle<T> {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in return .done(delivery(value)) }
        let _ = compose(deliveryWrapper)
        return ObserverHandle(identifier: identifier, listenable: listenable)
    }
}

public protocol ChainedObservableSequenceProtocol: ObservableSequenceProtocol where ListenableType == PredecessorType.ListenableType {
    associatedtype PredecessorType: ObservableSequenceProtocol
    typealias PredecessorContinuableOutputDelivery = (PredecessorType.OutputType?) -> ContinuationResult
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorContinuableOutputDelivery
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

public protocol ObserverProtocol: Observable {
    func process(_ value: ListenableOutputType?) throws -> Void
}

extension ObserverProtocol {
    public func process(_ value: ListenableOutputType?) throws -> Void {
        guard self.hasObservers else { return }
        self.observers.forEach { (pair) in
            let (identifier, observer) = pair
            do { _ = try observer.process(value) }
            catch { self.observers.removeValue(forKey: identifier) }
        }
    }
}

public final class Observer<T>: ObserverProtocol {
    public var description: String
    
    public var observers: [UUID : Consumer<T>] = [ : ]
    public typealias ListenableOutputType = T
    
    public init() {
        self.description = Utilities.standardizeDescription("ListenableSequence<\(type(of: T.self))>")
    }
}
