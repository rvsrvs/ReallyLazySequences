//
//  Utilities.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/29/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

public enum Result<T> {
    case success(T)
    case failure(Error)
    
    var successful: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
}

public enum ReallyLazySequenceOperationType: Equatable {
    case map
    case flatMap
    case compactMap
    case reduce
    case filter
    case dispatch
}

public enum ReallyLazySequenceError: Error {
    case isComplete
    case nonPushable
    case noListeners
    
    var description: String {
        switch self {
        case .isComplete:
            return "ReallyLazySequence has already completed.  Pushes not allowed"
        case .nonPushable:
            return "push may only be called on Sequences which are NOT already attached to producers"
        case .noListeners:
            return "No listeners available for producer to produce into"
        }
    }
}

func standardizeRLSDescription(_ description: String) -> String {
    return description
        .replacingOccurrences(of: ".Type", with: "")
        .replacingOccurrences(of: "Swift.", with: "")
}

