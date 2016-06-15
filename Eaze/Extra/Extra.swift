//
//  Extra.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 03-09-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//
//  For helper functions and extensions

import UIKit

/// Does nothing. Use as temporary code to keep 'no code' warnings away.
func foo() {
    print("Foo function called: this should not happen in release versions!")
}

/// Delays the execution of the given closure by he given amount of seconds
func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}