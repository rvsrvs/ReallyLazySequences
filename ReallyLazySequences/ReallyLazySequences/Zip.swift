//
//  Zip.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/23/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

import Foundation

//func zip<Sequence1, Sequence2>(_ sequence1: Sequence1, _ sequence2: Sequence2) -> Zip2Sequence<Sequence1, Sequence2> where Sequence1 : Sequence, Sequence2 : Sequence

public final class Zip2<T0, T1>: Listenable where T0: ListenerProtocol, T1: ListenerProtocol {
    public typealias ListenableOutputType = (T0.OutputType, T1.OutputType)
    
    public var listeners = [UUID: Consumer<(T0.OutputType, T1.OutputType)>]()
    public var hasListeners: Bool { return listeners.count > 0 }
    
    private var t0Proxy: ListenerHandle<T0.ListenableType>?
    private var t1Proxy: ListenerHandle<T1.ListenableType>?

    var value: (T0.OutputType?, T1.OutputType?)? {
        didSet {
            guard value != nil else {
                listeners.keys.forEach { uuid in
                    do { _ = try listeners[uuid]?.process(nil) }
                    catch { _ = remove(consumerWith: uuid) }
                }
                return
            }
            if  let v0 = value?.0,
                let v1 = value?.1 {
                let v = (v0, v1)
                listeners.keys.forEach { uuid in
                    do { _ = try listeners[uuid]?.process(v) }
                    catch { _ = remove(consumerWith: uuid) }
                }
                value = (nil, nil) as (T0.OutputType?, T1.OutputType?)
            }
        }
    }
    
    init(_ t0: T0, t1: T1) {
        self.value = (nil, nil) as (T0.OutputType?, T1.OutputType?)
        self.t0Proxy = nil
        self.t1Proxy = nil
        self.t0Proxy = t0.listen { [weak self] (t0: T0.OutputType?) -> ContinuationTermination in
            self?.value = (t0, self?.value?.1)
            return .canContinue
        }
        self.t1Proxy = t1.listen { [weak self] (t1: T1.OutputType?) -> ContinuationTermination in
            self?.value = (self?.value?.0, t1)
            return .canContinue
        }
    }
}
