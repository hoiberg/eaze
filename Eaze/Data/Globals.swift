//
//  Globals.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 28-08-15.
//  Copyright (c) 2016 Hangar42. All rights reserved.
//

import UIKit

// global variables
var dataStorage = DataStorage()
var bluetoothSerial = BluetoothSerial()
var msp = MSPInterpreter()
var console = AppLog()
var cliActive = false

// shortcuts
let notificationCenter = NotificationCenter.default,
    userDefaults = UserDefaults.standard

// NSUserDefaults keys
let DefaultsAutoConnectNewKey = "AutoConnectNew",
    DefaultsAutoConnectOldKey = "AutoConnectOld"
