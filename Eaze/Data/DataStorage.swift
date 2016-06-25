//
//  DataStorage.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 01-09-15.
//  Copyright (c) 2016 Hangar42. All rights reserved.
//

import UIKit

final class DataStorage {
    
    // 1 MSP_API_VERSION
    var apiVersion: Version = "0.0.0"
    var mspVersion = 0 // non-semver
    
    // 2 MSP_FC_VARIANT
    var flightControllerIdentifier = ""
    
    // 3 MSP_FC_VERSION
    var flightControllerVersion: Version = "0.0.0"
    
    // 4 MSP_BOARD_INFO
    var boardIdentifier =  ""
    var boardVersion = 0
    
    // 5 MSP_BUILD_INFO
    var buildInfo = ""
    
    // 54 MSP_CF_SERIAL_CONFIG
    var serialPorts: [SerialPortConfig] = []
    var mspBaudRate: UInt32 = 0 // pre 1.6.0
    var serialGPSBaudRate: UInt32 = 0 // pre 1.6.0
    var gpsPasstroughBaudrate: UInt32 = 0 // pre 1.6.0
    var cliBaudRate: UInt32 = 0 // pre 1.6.0
    
    // 57 MSP_PID_CONTROLLER
    var PIDController = 0
    
    // 61 MSP_ARMING_CONFIG
    var autoDisarmDelay     = 0
    var disarmKillsSwitch   = false
    
    // 64 MSP_RC_MAP
    var RC_MAP: [Int] = []
    
    // 66 MSP_BF_CONFIG
    var mixerConfiguration  = 0
    var BFFeatures          = 0
    var serialRXType        = 0
    var boardAlignRoll      = 0
    var boardAlignPitch     = 0
    var boardAlignYaw       = 0
    var currentScale        = 0
    var currentOffset       = 0
    
    // 73 MSP_LOOP_TIME
    var loopTime = 0
    
    // 101 MSP_STATUS
    var cycleTime       = 0 // u16
    var i2cError        = 0 // u16
    var activeSensors   = 0 // u16 ACC|BARO<<1|MAG<<2|GPS<<3|SONAR<<4
    var mode            = 0 // u32
    var profile         = 0 // u8
    
    // 102 MSP_RAW_IMU
    var accelerometer   = [0.0, 0.0, 0.0]
    var gyroscope       = [0.0, 0.0, 0.0]
    var magnetometer    = [0.0, 0.0, 0.0]
    
    // 105 MSP_RC
    var activeChannels = 0
    var channels = [Int](count: 32, repeatedValue: 0)
    
    // 108 MSP_ATTITUDE
    var attitude = [0.0, 0.0, 0.0] // x -180<>180 y -90<>90 z 0<>360
    
    // 110 MSP_ANALOG
    var voltage = 0.0
    var mAhDrawn: Int = 0
    var rssi: Int = 0
    var amperage = 0.0
    
    // 111 MSP_RC_TUNING
    var rcRate              = 0.0
    var rcExpo              = 0.0
    var throttleMid         = 0.0
    var throttleExpo        = 0.0
    var rollPitchRate       = 0.0 // pre 1.7.0 only
    var rollRate            = 0.0
    var pitchRate           = 0.0
    var yawRate             = 0.0
    var yawExpo             = 0.0 // available in >=1.10.0
    var dynamicThrottlePID  = 0.0
    var dynamicThrottleBreakpoint = 0 // avaiable in >=1.7.0
    
    // 112 MSP_PID
    var PIDs: [[Double]] = []
    
    // 114 MSP_MISC
    var midRc                   = 0
    var minThrottle             = 0
    var maxThrottle             = 0
    var minCommand              = 0
    var failsafeThrottle        = 0
    var gpsType                 = 0
    var gpsBaudrate             = 0
    var gpsUbxSbas              = 0
    var multiwiiCurrentOutput   = 0
    var rssiChannel             = 0
    var placeHolder2            = 0
    var magDeclination          = 0 // not checked ?
    var vBatScale               = 0
    var vBatMinCellVoltage      = 0
    var vBatMaxCellVoltage      = 0
    var vBatWarningCellVoltage  = 0
    
    // 116 MSP_BOXNAMES
    var auxConfigNames: [String] = []
    
    // 117 MSP_PIDNAMES
    var PIDNames: [String] = []
    
    // 119 MSP_BOXIDS
    var auxConfigIDs: [Int] = [] // For definitions, see Modes.md of the cleanflight wiki
    
    // 240 MSP_ACC_TRIM
    var accTrimPitch = 0
    var accTrimRoll  = 0
    
    // Helper variables
    var boardName: String {
        return boards.find({$0.identifier == boardIdentifier})?.name ?? "Unknown Board"
    }
    
    var flightControllerName: String {
        return flightControllerVariants.find({$0.identifier == flightControllerIdentifier})?.name ?? "Unknown firmware"
    }
    
    var activeFlightModes: [String] {
        get {
            var arr: [String] = []
            for i in 0 ..< auxConfigNames.count {
                if mode.bitCheck(i) {
                    arr.append(auxConfigNames[i])
                }
            }
            arr.sortInPlace() { $0 < $1 }
            return arr
        }
    }
    
    var PIDControllerNames: [String] {
        if apiVersion < "1.14.0" {
            return ["MultiWii (Old)",
                    "Multiwii (rewrite)",
                    "LuxFloat",
                    "MultiWii (2.3 - latest)",
                    "MultiWii (2.3 - hybrid)",
                    "Harakiri"]
        } else {
            return ["MultiWii (2.3)",
                    "Multiwii (rewrite)",
                    "LuxFloat"]
        }
    }

    
    // MARK: - Functions
    
    init() {
        // create pids array
        for _ in 0...9 {
            PIDs.append([0.0, 0.0, 0.0])
        }
    }
}