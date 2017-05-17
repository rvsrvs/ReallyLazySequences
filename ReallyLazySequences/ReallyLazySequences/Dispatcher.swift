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
typealias SequenceNumber = Int64

struct Dispatchable {
    var sequence: Int64
    var step: Int64
    var nextStep: Continuation
    
    func dispatch() -> Dispatchable?  {
        guard let next = self.nextStep() as? Continuation else { return nil }
        return Dispatchable(sequence: self.sequence, step: self.step+1, nextStep: next)
    }
}

class Dispatcher: Hashable, Equatable {
    enum DispatchStatus {
        case complete
        case hasNext
    }

    static func ==(left: Dispatcher, right: Dispatcher) -> Bool { return left.hashValue == right.hashValue }
    
    var hashValue: Int
    var steps: [SequenceNumber: Int64] = [:]
    var dispatchables: [SequenceNumber: Dispatchable] = [:]
    var nextSequence: Int64 = 0
    
    init() {
        dispatcherSequence += 1
        self.hashValue = dispatcherSequence - 1
    }
    
    func canDispatch(_ dispatchable: Dispatchable) -> Bool {
        let prev = steps.filter { $0.key < dispatchable.sequence }.min { $0.key < $1.key }
        return prev != nil ? dispatchable.step < prev!.value : true
    }
    
    func nextDispatchable() throws -> Dispatchable? {
        var dispatchable:Dispatchable? = nil
        try synchronized(self) {
            if let (k, _) = dispatchables.first(where: { (_,d) in canDispatch(d) }) {
                dispatchable = dispatchables.removeValue(forKey: k)
            }
        }
        return dispatchable
    }
    
    func insert(_ dispatchable: Dispatchable) throws -> DispatchStatus {
        try synchronized(self) {
            dispatchables[dispatchable.sequence] = dispatchable
            steps[dispatchable.sequence] = dispatchable.step
        }
        return .hasNext
    }
    
    func remove(_ dispatchable: Dispatchable) throws -> DispatchStatus {
        try synchronized(self) { steps.removeValue(forKey: dispatchable.sequence) }
        return .complete
    }
    
    func dispatch() throws -> DispatchStatus {
        guard let dispatchable = try self.nextDispatchable() else { return .complete }
        let next = dispatchable.dispatch()
        return next == nil ? try remove(dispatchable) : try insert(dispatchable)
    }
    
    func manage(_ continuation: @escaping Continuation) throws {
        nextSequence += 1
        let dispatchable = Dispatchable(sequence: nextSequence - 1, step: 0, nextStep: continuation)
        _ = try insert(dispatchable)
        var status: DispatchStatus
        repeat { status = try dispatch() } while (status == .hasNext)
    }
}

