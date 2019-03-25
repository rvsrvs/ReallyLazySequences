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

public protocol ObservableProtocol: class, CustomStringConvertible {
    associatedtype ObservableOutputType

    var observers: [ObserverHandle<Self> : Consumer<ObservableOutputType>] { get set }
    var observer: Observer<Self> { get }
    
    func remove(observer: ObserverHandle<Self>) -> Consumer<ObservableOutputType>?
    func terminate()
}

public extension ObservableProtocol {
    var hasObservers: Bool { return observers.count > 0 }
    
    func remove(observer: ObserverHandle<Self>) -> Consumer<ObservableOutputType>? {
        return observers.removeValue(forKey: observer)
    }
    
    func terminate() {
        observers.forEach { handle, observer in
            _ = ((try? observers[handle]?.process(nil)) as ContinuationResult??)
            _ = remove(observer: handle)
        }
    }

    var observer: Observer<Self> {
        return Observer<Self>(self) { (handle: ObserverHandle<Self>, consumer: Consumer<ObservableOutputType>) in
            self.observers[handle] = consumer
        }
    }
}

public struct ObserverHandle<T>: CustomStringConvertible, Equatable, Hashable where T: ObservableProtocol {
    public static func == (lhs: ObserverHandle<T>, rhs: ObserverHandle<T>) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public var description: String
    
    var identifier: UUID
    var observable: T?
    
    public init(identifier: UUID = UUID(), observable: T?) {
        self.identifier = identifier
        self.observable = observable
        self.description = Utilities.standardizeDescription(
            "\(observable?.description ?? "nil")   >> ObserverHandle<identifier = \"\(identifier)>\""
        )
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    public mutating func terminate() -> Consumer<T.ObservableOutputType>? {
        guard let m = observable else { return nil }
        let c = m.remove(observer: self)
        observable = nil
        return c
    }
}

public protocol ObservableSequenceProtocol: SequenceProtocol {
    associatedtype ObservableType: ObservableProtocol
    func observe(_ delivery: @escaping (OutputType?) -> ContinuationTermination) -> ObserverHandle<Self.ObservableType>
    func proxy() -> ObserverHandle<Self.ObservableType>
    
    func map<T>(_ transform: @escaping (OutputType) throws -> T ) -> ObservableMap<Self, T>
    func compactMap<T>(_ transform: @escaping (OutputType) throws -> T? ) -> ObservableCompactMap<Self, T>
    func flatMap<T>(_ transform: @escaping (OutputType) throws -> Subsequence<OutputType, T>) -> ObservableFlatMap<Self, T> 

    // Observable Chaining
    func dispatch(_ queue: OperationQueue) -> ObservableDispatch<Self, OutputType>
    func collect<T>(
        initialValue: @autoclosure @escaping () -> T,
        combine: @escaping (T, OutputType) throws -> T,
        until: @escaping (T, OutputType?) -> Bool
    ) -> ObservableReduce<Self, T>
    func reduce<T>(_ initialValue: T, _ combine: @escaping (T, OutputType) throws -> T) -> ObservableReduce<Self, T>
    func filter(_ filter: @escaping (OutputType) throws -> Bool ) -> ObservableFilter<Self, OutputType>
}

public struct Observer<T>: ObservableSequenceProtocol where T: ObservableProtocol {
    public typealias ObservableType = T
    public typealias InputType = T.ObservableOutputType
    public typealias OutputType = T.ObservableOutputType

    public var description: String

    public var installer: (ObserverHandle<T>, Consumer<T.ObservableOutputType>) -> Void
    private weak var observable: T?
    private let handle: ObserverHandle<T>

    init(_ observable: T, installer: @escaping (ObserverHandle<T>, Consumer<T.ObservableOutputType>) -> Void) {
        self.observable = observable
        self.handle = ObserverHandle<T>(observable: observable)
        self.installer = installer
        self.description = Utilities.standardizeDescription("\(observable.description) >> Observer<\(type(of: T.ObservableOutputType.self))>")
    }

    public func proxy() -> ObserverHandle<T> {
        return ObserverHandle(observable: observable)
    }

    public func compose(_ delivery: @escaping ContinuableOutputDelivery) -> ContinuableInputDelivery? {
        let consumer = Consumer<T.ObservableOutputType>(delivery: delivery)
        installer(handle, consumer)
        return nil
    }

    public func observe(_ delivery: @escaping (T.ObservableOutputType?) -> ContinuationTermination) -> ObserverHandle<T> {
        let deliveryWrapper = { (value: OutputType?) -> ContinuationResult in return .done(delivery(value)) }
        let _ = compose(deliveryWrapper)
        return ObserverHandle(observable: observable)
    }
}

public protocol ChainedObservableSequenceProtocol: ObservableSequenceProtocol where ObservableType == PredecessorType.ObservableType {
    associatedtype PredecessorType: ObservableSequenceProtocol
    typealias PredecessorContinuableOutputDelivery = (PredecessorType.OutputType?) -> ContinuationResult
    typealias Composer = (@escaping ContinuableOutputDelivery) -> PredecessorContinuableOutputDelivery
    var predecessor: PredecessorType { get set }
    var composer: Composer { get set }
    init(predecessor: PredecessorType, composer: @escaping Composer)
}

public final class Observable<T>: ObservableProtocol {
    public var observers: [ObserverHandle<Observable<T>> : Consumer<T>] = [ : ]
    
    public typealias ObservableOutputType = T

    public var description: String {
        return Utilities.standardizeDescription("ObservableSequence<\(type(of: T.self))>")
    }
    
    func process(_ value: ObservableOutputType?) throws -> Void {
        guard self.hasObservers else { return }
        self.observers.forEach { (pair) in
            let (identifier, observer) = pair
            do { _ = try observer.process(value) }
            catch { self.observers.removeValue(forKey: identifier) }
        }
    }
}
