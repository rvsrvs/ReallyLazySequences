//
//  Value.swift
//  ReallyLazySequences
//
//  Created by Van Simmons on 8/5/18.
//  Copyright © 2018 ComputeCycles, LLC. All rights reserved.
//

//public class CValue<T>: ReallyLazySequenceProtocol {
//    public typealias InputType = T
//    public typealias OutputType = T
//
//    private var delivery: OutputFunction?
//    
//    var value: T {
//        didSet {
//            if let delivery = delivery {
//                drive(delivery(value))
//            }
//        }
//    }
//    
//}


public struct Value<T>: ReallyLazySequenceProtocol {
    public typealias InputType = T
    public typealias OutputType = T
    
    typealias Getter = () -> T
    typealias Setter = (T) -> Void
    typealias ValueComposer = (@escaping OutputFunction) -> Void
    typealias Accessors = (getter: Getter , setter: Setter, composer: ValueComposer )
    
    var accessors: () -> Accessors
    
    public init(_ value: T) {
        accessors = {
            var accessedValue: T = value
            var setter: Setter = { newValue in
                accessedValue = newValue
            }
            let getter: Getter = { accessedValue }
            let composer: ValueComposer = { delivery in
                setter = { newValue in
                    accessedValue = newValue
                    drive(delivery(newValue))
                }
            }
            return (getter: getter, setter: setter, composer: composer)
        }
    }
    
    private var composer: ValueComposer {
        return accessors().composer
    }
    
    var value: T {
        get { return accessors().getter() }
        set { return accessors().setter(newValue) }
    }
    
    public func compose(_ output: (@escaping (T?) -> Continuation)) -> ((T?) throws -> Void) {
        composer(output)
        return { (value: T?) throws -> Void in
            throw ReallyLazySequenceError.nonPushable
        }
    }
}

public struct Tuple<T0, T1>: ReallyLazySequenceProtocol {
    public typealias InputType = (T0?, T1?)
    public typealias OutputType = (T0?, T1?)
    public typealias T = InputType
    
    typealias Getter1 = () -> T0?
    typealias Getter2 = () -> T1?
    typealias Getters = (Getter1, Getter2)
    typealias Getter = () -> InputType
    
    typealias Setter1 = (T0) -> Void
    typealias Setter2 = (T1) -> Void
    typealias Setters = (Setter1, Setter2)
    typealias Setter = (InputType) -> Void

    typealias ValueComposer = (@escaping OutputFunction) -> Void
    typealias Accessors = (getter: Getter, getters: Getters, setter: Setter, setters: Setters, composer: ValueComposer )
    
    var accessors: () -> Accessors
    
    public init() {
        accessors = {
            var accessedValue: T = (nil, nil)
            var setter: Setter = { newValue in
                accessedValue = newValue
            }
            var setters: Setters = (
                { newValue in accessedValue.0 = newValue },
                { newValue in accessedValue.1 = newValue }
            )
            let getter: Getter = { accessedValue }
            let getters: Getters = (
                { accessedValue.0 },
                { accessedValue.1 }
            )
            let composer: ValueComposer = { delivery in
                setter = { newValue in accessedValue = newValue; drive(delivery(accessedValue)) }
                setters = (
                    { newValue in accessedValue.0 = newValue; drive(delivery(accessedValue)) },
                    { newValue in accessedValue.1 = newValue; drive(delivery(accessedValue)) }
                )
            }
            return (getter: getter, getters: getters, setter: setter, setters: setters, composer: composer)
        }
    }
    
    private var composer: ValueComposer {
        return accessors().composer
    }
    
    var value: T {
        get { return accessors().getter() }
        set { return accessors().setter(newValue) }
    }
    
    public func compose(_ output: (@escaping (T?) -> Continuation)) -> ((T?) throws -> Void) {
        composer(output)
        return { (value: T?) throws -> Void in
            throw ReallyLazySequenceError.nonPushable
        }
    }
}
