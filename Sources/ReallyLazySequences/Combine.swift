//
//  Combine.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 4/2/19.
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
public func combine<T0, T1>(
    _ t0: T0,
    _ t1: T1,
    initialValue: (T0.OutputType, T1.OutputType)
) -> Combine2<T0, T1> where
    T0: ObservableSequenceProtocol,
    T1: ObservableSequenceProtocol {
        return Combine2(t0, t1, initialValue: initialValue)
}

public func combine<T0, T1, T2>(
    _ t0: T0,
    _ t1: T1,
    _ t2: T2,
    initialValue: (T0.OutputType, T1.OutputType, T2.OutputType)
) -> Combine3<T0, T1, T2> where
    T0: ObservableSequenceProtocol,
    T1: ObservableSequenceProtocol,
    T2: ObservableSequenceProtocol {
        return Combine3(t0, t1, t2, initialValue: initialValue)
}

public final class Combine2<T0, T1>: ObservableProtocol where
    T0: ObservableSequenceProtocol,
    T1: ObservableSequenceProtocol
{
    public var description: String
    
    public typealias ObservableOutputType = (T0.OutputType, T1.OutputType)
    
    public var observers = [ObserverHandle<Combine2<T0, T1>>: Consumer<(T0.OutputType, T1.OutputType)>]()
    public var hasObservers: Bool { return observers.count > 0 }
    
    private var t0Proxy: ObserverHandle<T0.ObservableType>!
    private var t1Proxy: ObserverHandle<T1.ObservableType>!
    
    private func send(_ v0: T0.OutputType, _ v1: T1.OutputType) {
        let v = (v0, v1)
        observers.forEach { handle, consumer in
            do { _ = try consumer.process(v) }
            catch { _ = remove(observer: handle) }
        }
    }
    
    var value: (T0.OutputType, T1.OutputType)? {
        didSet {
            guard let newValue = value else {
                observers.forEach { handle, consumer in
                    do { _ = try consumer.process(nil) }
                    catch { _ = remove(observer: handle) }
                }
                return
            }
            send(newValue.0, newValue.1)
        }
    }
    
    init(_ t0: T0, _ t1: T1, initialValue: (T0.OutputType, T1.OutputType)) {
        self.value = initialValue
        self.description = Utilities.standardizeDescription("Combine2<\n\t\(t0.description),\n\t\(t1.description)\n>")
        self.t0Proxy = t0.observe { [weak self] (t0: T0.OutputType?) -> ContinuationTermination in
            guard let strongSelf = self else { return .terminate }
            guard let t0 = t0, let value = strongSelf.value else {
                strongSelf.value = nil
                _ = strongSelf.t1Proxy.terminate()
                return .terminate
            }
            strongSelf.value = (t0, value.1)
            return .canContinue
        }
        self.t1Proxy = t1.observe { [weak self] (t1: T1.OutputType?) -> ContinuationTermination in
            guard let strongSelf = self else { return .terminate }
            guard let t1 = t1, let value = strongSelf.value else {
                strongSelf.value = nil
                _ = strongSelf.t0Proxy.terminate()
                return .terminate
            }
            strongSelf.value = (value.0, t1)
            return .canContinue
        }
    }
}

public final class Combine3<T0, T1, T2>: ObservableProtocol where
    T0: ObservableSequenceProtocol,
    T1: ObservableSequenceProtocol,
    T2: ObservableSequenceProtocol
{
    public var description: String
    
    public typealias ObservableOutputType = (T0.OutputType, T1.OutputType, T2.OutputType)
    
    public var observers = [ObserverHandle<Combine3<T0, T1, T2>>: Consumer<(T0.OutputType, T1.OutputType, T2.OutputType)>]()
    public var hasObservers: Bool { return observers.count > 0 }
    
    private var t0Proxy: ObserverHandle<T0.ObservableType>!
    private var t1Proxy: ObserverHandle<T1.ObservableType>!
    private var t2Proxy: ObserverHandle<T2.ObservableType>!

    private func send(_ v0: T0.OutputType, _ v1: T1.OutputType, _ v2: T2.OutputType) {
        let v = (v0, v1, v2)
        observers.forEach { handle, consumer in
            do { _ = try consumer.process(v) }
            catch { _ = remove(observer: handle) }
        }
    }
    
    var value: (T0.OutputType, T1.OutputType, T2.OutputType)? {
        didSet {
            guard let newValue = value else {
                observers.forEach { handle, consumer in
                    do { _ = try consumer.process(nil) }
                    catch { _ = remove(observer: handle) }
                }
                return
            }
            send(newValue.0, newValue.1, newValue.2)
        }
    }
    
    init(_ t0: T0, _ t1: T1, _ t2: T2, initialValue: (T0.OutputType, T1.OutputType, T2.OutputType)) {
        self.value = initialValue
        self.description = Utilities.standardizeDescription(
            "Combine3<\n\t\(t0.description),\n\t\(t1.description),\n\t\(t2.description)\n>"
        )
        self.t0Proxy = t0.observe { [weak self] (t0: T0.OutputType?) -> ContinuationTermination in
            guard let self = self, let t0 = t0, let value = self.value else { return .terminate }
            self.value = (t0, value.1, value.2)
            return .canContinue
        }
        self.t1Proxy = t1.observe { [weak self] (t1: T1.OutputType?) -> ContinuationTermination in
            guard let self = self, let t1 = t1, let value = self.value else { return .terminate }
            self.value = (value.0, t1, value.2)
            return .canContinue
        }
        self.t2Proxy = t2.observe { [weak self] (t2: T2.OutputType?) -> ContinuationTermination in
            guard let self = self, let t2 = t2, let value = self.value else { return .terminate }
            self.value = (value.0, value.1, t2)
            return .canContinue
        }
    }
}
