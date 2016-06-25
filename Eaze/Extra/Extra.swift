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