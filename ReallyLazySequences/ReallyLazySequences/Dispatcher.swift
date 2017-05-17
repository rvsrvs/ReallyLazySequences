//
//  Dispatcher.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 5/16/17.
//  Copyright © 2017 ComputeCycles, LLC. All rights reserved.
//

enum DispatcherError: Error {
    case notOwningThread
    case notInitialized
    case timedOut
    case failedEndSync
    
    var description: String {
        switch self {
        case .notOwningThread:
            return "Not owning thread"
        case .notInitialized:
            return "Not initialized"
        case .timedOut:
            return "Timed out"
        case .failedEndSync:
            return "Failed to end sync"
        }
    }
}

func synchronized(_ token: AnyHashable, operation: (Void) -> Void) throws {
    let canSync = objc_sync_enter(token)
    if canSync == Int32(OBJC_SYNC_SUCCESS) {
        operation()
        let syncCompletion = objc_sync_exit(token)
        if syncCompletion != Int32(OBJC_SYNC_SUCCESS) {
            throw DispatcherError.failedEndSync
        }
    } else if canSync == Int32(OBJC_SYNC_NOT_OWNING_THREAD_ERROR) {
        throw DispatcherError.notOwningThread
    } else if canSync == Int32(OBJC_SYNC_NOT_INITIALIZED) {
        throw DispatcherError.notInitialized
    } else if canSync == Int32(OBJC_SYNC_TIMED_OUT) {
        throw DispatcherError.timedOut
    }
}

fileprivate var dispatcherSequence: Int = 0
class Dispatcher: Hashable, Equatable {

    static func ==(left: Dispatcher, right: Dispatcher) -> Bool {
        return left.hashValue == right.hashValue
    }
    
    var hashValue: Int
    var steps: [Int64: Int64] = [:]
    var dispatchables: [Int64: Dispatchable] = [:]
    var nextSequence: Int64 = 0
    
    init() {
        self.hashValue = dispatcherSequence + 1
        dispatcherSequence += 1
    }
    
    func canDispatch(_ dispatchable: Dispatchable) -> Bool {
        let prev = steps.filter { $0.key < dispatchable.sequence }.min { $0.key < $1.key }
        if let prev = prev {
            return dispatchable.step < prev.value
        } else {
            return true
        }
    }
    
    func dispatch() throws {
        var dispatchable:Dispatchable? = nil
        try synchronized(self) {
            for (k,d) in dispatchables {
                if canDispatch(d) {
                    dispatchable = dispatchables.removeValue(forKey: k)
                    break
                }
            }
        }
        if dispatchable != nil { print("dispatch!") } else { print("nothing to do") }
        if let newDispatchable = dispatchable?.dispatch() {
            try synchronized(self) {
                dispatchables[newDispatchable.sequence] = newDispatchable
                steps[newDispatchable.sequence] = newDispatchable.step
            }
            try dispatch()
        } else {
            try synchronized(self) {
                if let dispatchable = dispatchable {
                    steps.removeValue(forKey: dispatchable.sequence)
                }
            }
            return
        }
    }
    
    func manage(_ continuation: @escaping Continuation) throws {
        try synchronized(self) {
            let dispatchAble = Dispatchable(sequence: nextSequence, step: 0, nextStep: continuation)
            steps[nextSequence] = 0
            dispatchables[nextSequence] = dispatchAble
            nextSequence += 1
        }
        try dispatch()
    }
}

struct Dispatchable {
    var sequence: Int64
    var step: Int64
    var nextStep: Continuation
    
    func dispatch() -> Dispatchable?  {
        guard let next = self.nextStep() as? Continuation else { return nil }
        return Dispatchable(sequence: self.sequence, step: self.step+1, nextStep: next)
    }
}
