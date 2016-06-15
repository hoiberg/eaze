//
//  Globals.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 28-08-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//

import UIKit

// global variables
var globals = Globals()
var dataStorage = DataStorage()
var bluetoothSerial: BluetoothSerial!
var msp = MSPInterpreter()
var console = AppLog()
var cliActive = false

// shortcuts
let notificationCenter = NSNotificationCenter.defaultCenter(),
    userDefaults = NSUserDefaults.standardUserDefaults()

// NSUserDefaults keys
let DefaultsAutoConnectNewKey = "AutoConnectNew",
    DefaultsAutoConnectOldKey = "AutoConnectOld"

// Development related global variables
let xxPrintAsWell = true // whether to print to the device console as well as app log


final class Globals {

    // buttons
    let colorTint               = UIColor(red: 72/255, green: 160/255, blue: 23/255, alpha: 1.0) // cleanflight green
    let colorSelection          = UIColor(red: 62/255, green: 140/255, blue: 15/255, alpha: 1.0) // dark green
    let colorTextOnTint         = UIColor.whiteColor()
    
    // other
    let colorBackground         = UIColor.whiteColor()
    let colorTextOnBackground   = UIColor.blackColor()
    
    // table views
    let colorTableBackground    = UIColor.groupTableViewBackgroundColor() // UIColor(red: 239/255, green: 239/255, blue: 243/255, alpha: 1.0) // default grouped tableView background
    let colorTableSelectedBackground = UIColor(hex: 0xD0D0D0)
    let colorCellBackground     = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
    
    init() { }
}


