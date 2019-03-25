//
//  Zip.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/23/18.
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

//func zip<Sequence1, Sequence2>(_ sequence1: Sequence1, _ sequence2: Sequence2) -> Zip2Sequence<Sequence1, Sequence2> where Sequence1 : Sequence, Sequence2 : Sequence

public func zip<T0, T1>(_ t0: T0, _ t1: T1) -> Zip2<T0, T1> where
    T0: ObservableSequenceProtocol,
    T1: ObservableSequenceProtocol {
    return Zip2(t0, t1)
}

public final class Zip2<T0, T1>: Observable where
    T0: ObservableSequenceProtocol,
    T1: ObservableSequenceProtocol {
    public var description: String
    
    public typealias ListenableOutputType = (T0.OutputType, T1.OutputType)
    
    public var observers = [UUID: Consumer<(T0.OutputType, T1.OutputType)>]()
    public var hasObservers: Bool { return observers.count > 0 }
    
    private var t0Proxy: ObserverHandle<T0.ListenableType>?
    private var t1Proxy: ObserverHandle<T1.ListenableType>?
    
    private var t0Queue: [T0.OutputType?] = []
    private var t1Queue: [T1.OutputType?] = []

    private func sendIfNecessary(_ v0: T0.OutputType?, _ v1: T1.OutputType?) -> Bool {
        if  let v0 = value?.0, let v1 = value?.1 {
            let v = (v0, v1)
            observers.keys.forEach { uuid in
                do { _ = try observers[uuid]?.process(v) }
                catch { _ = remove(uuid) }
            }
            return true
        }
        return false
    }
    
    var value: (T0.OutputType?, T1.OutputType?)? {
        didSet {
            guard value != nil else {
                observers.keys.forEach { uuid in
                    do { _ = try observers[uuid]?.process(nil) }
                    catch { _ = remove(uuid) }
                }
                return
            }
            if sendIfNecessary(value?.0, value?.1) {
                value = (nil, nil) as (T0.OutputType?, T1.OutputType?)
                var sent = false
                repeat {
                    if t0Queue.count > 0, let v0 = t0Queue.remove(at: 0) { value?.0 = v0 }
                    if t1Queue.count > 0, let v1 = t1Queue.remove(at: 0) { value?.1 = v1 }
                    sent = sendIfNecessary(value?.0, value?.1) 
                } while sent
            }
        }
    }
    
    init(_ t0: T0, _ t1: T1) {
        self.value = (nil, nil) as (T0.OutputType?, T1.OutputType?)
        self.description = Utilities.standardizeDescription("Zip2<\n\t\(t0.description),\n\t\(t1.description)\n>")
        self.t0Proxy = nil
        self.t1Proxy = nil
        self.t0Proxy = t0.listen { [weak self] (t0: T0.OutputType?) -> ContinuationTermination in
            guard let strongSelf = self else { return .terminate }
            guard let t0 = t0 else { strongSelf.value = nil; return .terminate }
            guard strongSelf.value?.0 == nil else { strongSelf.t0Queue.append(t0); return .canContinue }
            strongSelf.value = (t0, self?.value?.1)
            return .canContinue
        }
        self.t1Proxy = t1.listen { [weak self] (t1: T1.OutputType?) -> ContinuationTermination in
            guard let strongSelf = self else { return .terminate }
            guard let t1 = t1 else { strongSelf.value = nil; return .terminate }
            guard strongSelf.value?.1 == nil else { strongSelf.t1Queue.append(t1); return .canContinue }
            strongSelf.value = (self?.value?.0, t1)
            return .canContinue
        }
    }
}
