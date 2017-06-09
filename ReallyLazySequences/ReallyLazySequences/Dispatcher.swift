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

func synchronized(_ token: AnyHashable, operation: () -> Void) throws {
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

struct Dispatchable {
    var sequence: SequenceNumber
    var step: SequenceNumber
    var nextStep: Continuation
    
    func dispatch() -> Dispatchable?  {
        guard let next = self.nextStep() as? Continuation else { return nil }
        return Dispatchable(sequence: self.sequence, step: self.step+1, nextStep: next)
    }
}

typealias SequenceNumber = Int64
fileprivate var dispatcherSequence: Int = 0

enum DispatchStatus {
    case complete
    case hasNext
}

protocol DispatcherProtocol {
    func dispatch(_ continuation: @escaping Continuation) throws -> Void
    func dispatch() throws -> DispatchStatus
}

class Dispatcher: DispatcherProtocol {
    func dispatch() throws -> DispatchStatus {
        return .complete
    }

    func dispatch(_ continuation: @escaping Continuation) throws {
        var nextDelivery: Continuation? = continuation() as? Continuation
        while nextDelivery != nil { nextDelivery = nextDelivery!() as? Continuation }
    }
}

class ThreadSafeDispatcher: DispatcherProtocol, Hashable, Equatable {
    static func ==(left: ThreadSafeDispatcher, right: ThreadSafeDispatcher) -> Bool {
        return left.hashValue == right.hashValue
    }
    
    var hashValue: Int
    var steps: [SequenceNumber: Int64] = [:]
    var dispatchables: [SequenceNumber: Dispatchable] = [:]
    var nextSequence: SequenceNumber = 0
    
    init() {
        dispatcherSequence += 1
        self.hashValue = dispatcherSequence - 1
    }
    
    func canDispatch(_ dispatchable: Dispatchable) -> Bool {
        let prev = steps.filter { $0.key < dispatchable.sequence }.min { $0.key < $1.key }
        return prev == nil ? true : dispatchable.step < prev!.value
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
        var status = DispatchStatus.complete
        try synchronized(self) {
            steps.removeValue(forKey: dispatchable.sequence)
            status = steps.count > 0 ? .hasNext : .complete
        }
        return status
    }
    
    func dispatch() throws -> DispatchStatus {
        guard let dispatchable = try nextDispatchable() else { return .complete }
        if let dispatchable = dispatchable.dispatch() {
            return try insert(dispatchable)
        } else {
            return try remove(dispatchable)
        }
    }
    
    func dispatch(_ continuation: @escaping Continuation) throws {
        nextSequence += 1
        let dispatchable = Dispatchable(sequence: nextSequence - 1, step: 0, nextStep: continuation)
        var status = try insert(dispatchable)
        while (status == .hasNext) { status = try dispatch() }
    }
}

