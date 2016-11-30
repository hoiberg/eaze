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
func delay(_ delay: Double, callback: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: callback)
}

protocol Copyable {
    init(copy: Self)
}

protocol ConfigScreen {
    /// Called when the view will become the active config screen (e.g. tab selected).
    /// Not the same as viewWillAppear, as it won't be called after e.g. an unwind segue
    func willBecomePrimaryView()
    
    /// Called when the view will seize to be the active config screen (e.g. other tab selected).
    /// Not the same as viewWillDisappear, as it won't be called when e.g. a modal screen comes up.
    //func willSeizeToBePrimary()
}

class WeakSet<ObjectType>: Sequence {
    
    var count: Int {
        return weakStorage.count
    }
    
    fileprivate let weakStorage = NSHashTable<AnyObject>.weakObjects()
    
    init() {}
    
    init(_ object: ObjectType) {
        addObject(object)
    }
    
    init(_ objects: [ObjectType]) {
        for object in objects {
            addObject(object)
        }
    }
    
    func addObject(_ object: ObjectType) {
        weakStorage.add(object as AnyObject?)
    }
    
    func removeObject(_ object: ObjectType) {
        weakStorage.remove(object as AnyObject?)
    }
    
    func removeAllObjects() {
        weakStorage.removeAllObjects()
    }
    
    func containsObject(_ object: ObjectType) -> Bool {
        return weakStorage.contains(object as AnyObject?)
    }
    
    func makeIterator() -> AnyIterator<ObjectType> {
        let enumerator = weakStorage.objectEnumerator()
        return AnyIterator {
            return enumerator.nextObject() as! ObjectType?
        }
    }
}
