//
//  Extra.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 03-09-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//
//  For helper functions and extensions

import UIKit

/// Delays the execution of the given closure by the given amount of seconds
func delay(delay: Double, callback: ()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), callback)
}

protocol Copyable {
    init(copy: Self)
}

class WeakSet<ObjectType>: SequenceType {
    
    var count: Int {
        return weakStorage.count
    }
    
    private let weakStorage = NSHashTable.weakObjectsHashTable()
    
    init() {}
    
    init(_ object: ObjectType) {
        addObject(object)
    }
    
    init(_ objects: [ObjectType]) {
        for object in objects {
            addObject(object)
        }
    }
    
    func addObject(object: ObjectType) {
        guard object is AnyObject else { fatalError("Object (\(object)) should be subclass of AnyObject") }
        weakStorage.addObject(object as? AnyObject)
    }
    
    func removeObject(object: ObjectType) {
        guard object is AnyObject else { fatalError("Object (\(object)) should be subclass of AnyObject") }
        weakStorage.removeObject(object as? AnyObject)
    }
    
    func removeAllObjects() {
        weakStorage.removeAllObjects()
    }
    
    func containsObject(object: ObjectType) -> Bool {
        guard object is AnyObject else { fatalError("Object (\(object)) should be subclass of AnyObject") }
        return weakStorage.containsObject(object as? AnyObject)
    }
    
    func generate() -> AnyGenerator<ObjectType> {
        let enumerator = weakStorage.objectEnumerator()
        return AnyGenerator {
            return enumerator.nextObject() as! ObjectType?
        }
    }
}
