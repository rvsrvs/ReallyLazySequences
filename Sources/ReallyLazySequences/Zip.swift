//
//  Zip.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/23/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

//func zip<Sequence1, Sequence2>(_ sequence1: Sequence1, _ sequence2: Sequence2) -> Zip2Sequence<Sequence1, Sequence2> where Sequence1 : Sequence, Sequence2 : Sequence

public func zip<T0, T1>(_ t0: T0, _ t1: T1) -> Zip2<T0, T1> where
    T0: ListenableSequenceProtocol,
    T1: ListenableSequenceProtocol {
    return Zip2(t0, t1)
}

public final class Zip2<T0, T1>: Listenable where
    T0: ListenableSequenceProtocol,
    T1: ListenableSequenceProtocol {
    public var description: String
    
    public typealias ListenableOutputType = (T0.OutputType, T1.OutputType)
    
    public var listeners = [UUID: Consumer<(T0.OutputType, T1.OutputType)>]()
    public var hasListeners: Bool { return listeners.count > 0 }
    
    private var t0Proxy: ListenerHandle<T0.ListenableType>?
    private var t1Proxy: ListenerHandle<T1.ListenableType>?
    
    private var t0Queue: [T0.OutputType?] = []
    private var t1Queue: [T1.OutputType?] = []

    private func sendIfNecessary(_ v0: T0.OutputType?, _ v1: T1.OutputType?) -> Bool {
        if  let v0 = value?.0, let v1 = value?.1 {
            let v = (v0, v1)
            listeners.keys.forEach { uuid in
                do { _ = try listeners[uuid]?.process(v) }
                catch { _ = remove(uuid) }
            }
            return true
        }
        return false
    }
    
    var value: (T0.OutputType?, T1.OutputType?)? {
        didSet {
            guard value != nil else {
                listeners.keys.forEach { uuid in
                    do { _ = try listeners[uuid]?.process(nil) }
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
        self.description = standardizeRLSDescription("Zip2<\n\t\(t0.description),\n\t\(t1.description)\n>")
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
