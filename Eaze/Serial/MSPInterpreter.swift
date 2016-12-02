//
//  MSPInterpreter.swift
//  Cleanflight Mobile Configurator
//
//  MSP = Multiwii Serial Protocol
//
//  Created by Alex on 01-09-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//

/**
 * MSP Guidelines, emphasis is used to clarify (taken from cleanfligth/src/main/io/msp_protocol.h)
 *
 * Each FlightController (FC, Server) MUST change the API version when any MSP command is added, deleted, or changed.
 *
 * If you fork the FC source code and release your own version, you MUST change the Flight Controller Identifier.
 *
 * NEVER release a modified copy of the FC MSP code that shares the same Flight controller IDENT and API version
 * if the API doesn't match EXACTLY.
 *
 * Consumers of the API (API clients) SHOULD first attempt to get a response from the MSP_API_VERSION command.
 * If no response is obtained then client MAY try the legacy MSP_IDENT command.
 *
 * API consumers should ALWAYS handle communication failures gracefully and attempt to continue
 * without the information if possible.  Clients MAY log/display a suitable message.
 *
 * API clients should NOT attempt any communication if they can't handle the returned API MAJOR VERSION.
 *
 * API clients SHOULD attempt communication if the API MINOR VERSION has increased from the time
 * the API client was written and handle command failures gracefully.  Clients MAY disable
 * functionality that depends on the commands while still leaving other functionality intact.
 * that the newer API version may cause problems before using API commands that change FC state.
 *
 * It is for this reason that each MSP command should be specific as possible, such that changes
 * to commands break as little functionality as possible.
 *
 * API client authors MAY use a compatibility matrix/table when determining if they can support
 * a given command from a given flight controller at a given api version level.
 *
 * Developers MUST NOT create new MSP commands that do more than one thing.
 *
 * Failure to follow these guidelines will likely invoke the wrath of developers trying to write tools
 * that use the API and the users of those tools.
 */

import UIKit

protocol MSPUpdateSubscriber: AnyObject, NSObjectProtocol {
    func mspUpdated(_ code: Int)
}

// MSP codes
let MSP_API_VERSION     = 1
let MSP_FC_VARIANT      = 2
let MSP_FC_VERSION      = 3
let MSP_BOARD_INFO      = 4
let MSP_BUILD_INFO      = 5

// MSP codes Cleanflight original features
let MSP_MODE_RANGE           = 34
let MSP_SET_MODE_RANGE       = 35
let MSP_FEATURE              = 36 // replacing BF_CONFIG est 1.25.0 (only CLFL)
let MSP_SET_FEATURE          = 37 // replacing BF_CONFIG est 1.25.0 (only CLFL)
let MSP_BOARD_ALIGNMENT      = 38 // replacing BF_CONFIG est 1.25.0 (only CLFL)
let MSP_SET_BOARD_ALIGNMENT  = 39 // replacing BF_CONFIG est 1.25.0 (only CLFL)
let MSP_MIXER                = 42 // replacing BF_CONFIG est 1.25.0 (only CLFL)
let MSP_SET_MIXER            = 43 // replacing BF_CONFIG est 1.25.0 (only CLFL)
let MSP_RX_CONFIG            = 44 // replaced BF_CONFIG in api 1.25.0 (only CLFL)
let MSP_SET_RX_CONFIG        = 45 // replaced BF_CONFIG in api 1.25.0 (only CLFL)
let MSP_CF_SERIAL_CONFIG     = 54 // min 1.6.0 (older versions not supported) not the same for all API versions
let MSP_SET_CF_SERIAL_CONFIG = 55 // min 1.6.0 (older versions not supported) not the same for all API versions
let MSP_PID_CONTROLLER       = 59 // min 1.5.0
let MSP_SET_PID_CONTROLLER   = 60 // min 1.5.0
let MSP_ARMING_CONFIG        = 61 // min 1.8.0
let MSP_SET_ARMING_CONFIG    = 62 // min 1.8.0

// MSP codes for Baseflight configurator
let MSP_RX_MAP          = 64
let MSP_SET_RX_MAP      = 65
let MSP_BF_CONFIG       = 66
let MSP_SET_BF_CONFIG   = 67
let MSP_SET_REBOOT      = 68

// MSP codes Cleanflight original features
let MSP_LOOP_TIME       = 73 // min 1.8.0
let MSP_SET_LOOP_TIME   = 74 // min 1.8.0

// MSP codes Multiwi
let MSP_STATUS          = 101
let MSP_RAW_IMU         = 102
let MSP_RC              = 105
let MSP_ATTITUDE        = 108
let MSP_ANALOG          = 110
let MSP_RC_TUNING       = 111 // not the same for all API versions
let MSP_PID             = 112
let MSP_MISC            = 114
let MSP_BOXNAMES        = 116
let MSP_PIDNAMES        = 117
let MSP_BOXIDS          = 119
let MSP_SET_PID         = 202
let MSP_SET_RC_TUNING   = 204 // not the same for all API versions
let MSP_ACC_CALIBRATION = 205
let MSP_MAG_CALIBRATION = 206
let MSP_SET_MISC        = 207
let MSP_RESET_CONF      = 208
let MSP_SELECT_SETTING  = 210
let MSP_SET_ACC_TRIM    = 239
let MSP_ACC_TRIM        = 240
let MSP_EEPROM_WRITE    = 250


final class MSPInterpreter: BluetoothSerialDelegate {
    
    var subscribers = [Int: WeakSet<MSPUpdateSubscriber>]()
    var callbacks: [(code: Int, callback: (Void) -> Void)] = []
    
    var state = 0
    var messageDirection: UInt8 = 0
    var messageCode: Int = 0
    var messageLengthExpected: UInt8 = 0
    var messageLengthReceived: UInt8 = 0
    var messageData: [UInt8] = []
    var messageChecksum: UInt8 = 0
    
    func serialPortReceivedData(_ data: Data) {
        var bytes = [UInt8](repeating: 0, count: data.count / MemoryLayout<UInt8>.size)
        (data as NSData).getBytes(&bytes, length: data.count)
        interpretMSP(bytes)
    }
    
    func interpretMSP(_ data: [UInt8]) {
        for byte in data {
            switch (state) {
            case 0: // sync char '$'
                if byte == 36 { state += 1 }
                
            case 1: // sync char 'M'
                if byte == 77 { state += 1 }
                else { state = 0; log(.Error, "Incorrect MSP message: expected 'M' but found \(byte)") } // try again
                
            case 2: // direction '>' or '<' (should be '>')
                if byte == 62 { messageDirection = 1 }
                else { messageDirection = 0 } // ??
                state += 1
                
            case 3: // length
                messageLengthExpected = byte
                messageChecksum = byte
                state += 1
                
            case 4: // code
                messageCode = Int(byte)
                messageChecksum ^= byte
                if messageLengthExpected > 0 {
                    state += 1
                } else {
                    state += 2 // there ain't no data
                }
                
            case 5: // dataaaa
                messageData.append(byte)
                messageChecksum ^= byte
                messageLengthReceived += 1
                
                if messageLengthReceived >= messageLengthExpected {
                    state += 1
                }
                
            case 6: // checksum
                if messageChecksum == byte {
                    processData(messageCode, data: messageData)
                } else {
                    log(.Error, "Checksum not correct! Code: \(messageCode), Data: \(messageData), Expected checksum: \(messageChecksum), Received checksum: \(byte)")
                }
                
                reset()
            default:
                log(.Error, "Unknown state: \(state)")
            }
        }
    }
    
    func processData(_ code: Int, data: [UInt8]) {
        func check(_ length: Int) -> Bool {
            if data.count < length {
                log(.Error, "Expected \(length) bytes but received \(data.count) for MSP code \(code) with data: \(data)")
                reset()
                return false
            }
            return true
        }
        
        switch code {
        case MSP_API_VERSION: // 1
            guard check(3) else { return }
            dataStorage.apiVersion = Version(major: data[1], minor: data[2], patch: 0)
            dataStorage.mspVersion = Int(data[0])
            
        case MSP_FC_VARIANT: // 2
            guard check(4) else { return }            
            dataStorage.flightControllerIdentifier = String(bytes: data[0...3], encoding: String.Encoding.utf8) ?? ""

        case MSP_FC_VERSION: // 3
            guard check(3) else { return }
            dataStorage.flightControllerVersion = Version(major: data[0], minor: data[1], patch: data[2])
            
        case MSP_BOARD_INFO: // 4
            guard check(5) else { return }
            dataStorage.boardIdentifier = String(bytes: data[0...3], encoding: String.Encoding.utf8) ?? ""
            dataStorage.boardVersion = Int(getUInt16(data, offset: 4))
            
        case MSP_BUILD_INFO: // 5
            guard check(19) else { return }
            dataStorage.buildInfo = String(bytes: data[0...10], encoding: String.Encoding.utf8) ?? "" // date
            dataStorage.buildInfo += " " // space
            dataStorage.buildInfo += String(bytes: data[11...18], encoding: String.Encoding.utf8) ?? "" // time
            
        case MSP_MODE_RANGE: // 34
            dataStorage.modeRanges = []
            var offset = 0
            for _ in 0 ..< data.count/4 {
                var modeRange = ModeRange(id: Int(data[offset++]))
                modeRange.auxChannelIndex = Int(data[offset++])
                modeRange.range.start = 900 + Int(data[offset++]) * 25
                modeRange.range.end = 900 + Int(data[offset++]) * 25
                dataStorage.modeRanges.append(modeRange)
            }
            
        case MSP_SET_MODE_RANGE: // 35
            log("MSP_SET_MODE_RANGE received")
            
        case MSP_FEATURE: // 36
            dataStorage.BFFeatures = Int(getUInt32(data, offset: 0))
            
        case MSP_SET_FEATURE: // 37
            log("MSP_SET_FEATURE received")
            
        case MSP_BOARD_ALIGNMENT: // 38
            dataStorage.boardAlignRoll      = Int(getInt16(data, offset: 0)) // -180 - 360
            dataStorage.boardAlignPitch     = Int(getInt16(data, offset: 2)) // -180 - 360
            dataStorage.boardAlignYaw       = Int(getInt16(data, offset: 4)) // -180 - 360

        case MSP_SET_BOARD_ALIGNMENT: // 39
            log("MSP_SET_BOARD_ALIGNMENT received")
            
        case MSP_MIXER: // 42
            dataStorage.mixerConfiguration = Int(data[0]) - 1
            
        case MSP_SET_MIXER: // 43
            log("MSP_SET_MIXER received")
            
        case MSP_RX_CONFIG: // 44
            var offset = 0
            dataStorage.serialRXType = Int(data[offset])
            offset += 1
            dataStorage.stickMax = Int(getUInt16(data, offset: offset))
            offset += 2
            dataStorage.stickCenter = Int(getUInt16(data, offset: offset))
            offset += 2
            dataStorage.stickMin = Int(getUInt16(data, offset: offset))
            offset += 2
            dataStorage.satBind = Int(data[offset])
            offset += 1
            dataStorage.rxMinuSec = Int(getUInt16(data, offset: offset))
            offset += 2
            dataStorage.rxMaxuSec = Int(getUInt16(data, offset: offset))
            
        case MSP_SET_RX_CONFIG: // 45
            log("MSP_SET_RX_CONFIG received")
            
        case MSP_CF_SERIAL_CONFIG: // 54
            dataStorage.serialPorts = []
            if dataStorage.apiVersion >= "1.6.0" {
                var offset = 0
                let serialPortCount = data.count / 7
                for _ in 0 ..< serialPortCount {
                    var port = SerialPortConfig()
                    port.identifier = Int(data[offset])
                    for function in SerialPortFunction.all {
                        if ((UInt16(1) << UInt16(function.rawValue)) & getUInt16(data, offset: offset + 1)) > 0 {
                            port.functions.append(function)
                        }
                    }
                    port.MSP_baudrate = Baudrate(rawValue: Int(data[offset + 3]))!
                    port.GPS_baudrate = Baudrate(rawValue: Int(data[offset + 4]))!
                    port.TELEMETRY_baudrate = Baudrate(rawValue: Int(data[offset + 5]))!
                    port.BLACKBOX_baudrate = Baudrate(rawValue: Int(data[offset + 6]))!
                    offset += 7
                    dataStorage.serialPorts.append(port)
                }
            }
            
        case MSP_SET_CF_SERIAL_CONFIG: // 55
            log("MSP_SET_CF_SERIAL_CONFIG received")
            
        case MSP_PID_CONTROLLER: // 59
            guard check(1) else { return }
            dataStorage.PIDController = Int(data[0])
            
        case MSP_SET_PID_CONTROLLER: // 60
            log("MSP_SET_PID_CONTROLLER received")
            
        case MSP_ARMING_CONFIG: // 61
            if dataStorage.apiVersion >= "1.8.0" {
                guard check(2) else { return }
                dataStorage.autoDisarmDelay = Int(data[0])
                dataStorage.disarmKillsSwitch = data[1] != 0
            }
            
        case MSP_SET_ARMING_CONFIG: // 62
            log("MSP_SET_ARMING_CONFIG received")
            
        case MSP_RX_MAP: // 64
            dataStorage.RC_MAP = []
            for byte in data {
                dataStorage.RC_MAP.append(Int(byte))
            }
            
        case MSP_SET_RX_MAP: // 65
            log("MSP_SET_RX_MAP received")
            
        case MSP_BF_CONFIG: // 66
            guard check(16) else { return }
            dataStorage.mixerConfiguration  = Int(data[0]) - 1
            dataStorage.BFFeatures          = Int(getUInt32(data, offset: 1))
            dataStorage.serialRXType        = Int(data[5])
            dataStorage.boardAlignRoll      = Int(getInt16(data, offset: 6)) // -180 - 360
            dataStorage.boardAlignPitch     = Int(getInt16(data, offset: 8)) // -180 - 360
            dataStorage.boardAlignYaw       = Int(getInt16(data, offset: 10)) // -180 - 360
            dataStorage.currentScale        = Int(getInt16(data, offset: 12))
            dataStorage.currentOffset       = Int(getUInt16(data, offset: 14))
            
        case MSP_SET_BF_CONFIG: // 67
            log("MSP_SET_BF_CONFIG received")
            
        case MSP_SET_REBOOT: // 68
            log("Reboot request accepted")
            // detect reboot
            var done = false
            func ready() {
                done = true
                log("FC Reboot finished")
                MessageView.show("Reboot Finished")
            }
            func retry() {
                guard !done else { return }
                sendMSP(MSP_API_VERSION)
                delay(1, callback: retry)
            }
            sendMSP(MSP_API_VERSION, callback: ready)
            delay(1, callback: retry)
            
        case MSP_LOOP_TIME: // 73
            if dataStorage.apiVersion >= "1.8.0" {
                guard check(1) else { return }
                dataStorage.loopTime = Int(getInt16(data, offset: 0))
            }
            
        case MSP_SET_LOOP_TIME: // 74
            log("MSP_SET_LOOP_TIME received")
            
        case MSP_STATUS: // 101
            guard check(11) else { return }
            dataStorage.cycleTime = Int(getUInt16(data, offset: 0))
            dataStorage.i2cError = Int(getUInt16(data, offset: 2))
            dataStorage.activeSensors = Int(getUInt16(data, offset: 4))
            dataStorage.mode = Int(getUInt32(data, offset: 6))
            dataStorage.profile = Int(data[10])
            
        case MSP_RAW_IMU: // 102
            guard check(18) else { return }
            // 512 for MPU6050, 256 for MMA
            // Currently we are unable to differentiate between the sensor types, so we are going with 512
            dataStorage.accelerometer[0] = Double(getInt16(data, offset: 0)) / 512.0
            dataStorage.accelerometer[1] = Double(getInt16(data, offset: 2)) / 512.0
            dataStorage.accelerometer[2] = Double(getInt16(data, offset: 4)) / 512.0
            
            // Properly scaled
            dataStorage.gyroscope[0] = Double(getInt16(data, offset: 6)) * 4.0/16.4
            dataStorage.gyroscope[1] = Double(getInt16(data, offset: 8)) * 4.0/16.4
            dataStorage.gyroscope[2] = Double(getInt16(data, offset: 10)) * 4.0/16.4
            
            // Scaling factor unknown
            dataStorage.magnetometer[0] = Double(getInt16(data, offset: 12)) / 1090
            dataStorage.magnetometer[1] = Double(getInt16(data, offset: 14)) / 1090
            dataStorage.magnetometer[2] = Double(getInt16(data, offset: 16)) / 1090
            
        case MSP_RC: // 105
            dataStorage.activeChannels = data.count / 2
            for i in 0 ..< dataStorage.activeChannels {
                dataStorage.channels[i] = Int(getUInt16(data, offset: i * 2))
            }
            
        case MSP_ATTITUDE: // 108
            guard check(6) else { return }
            dataStorage.attitude[0] = Double(getInt16(data, offset: 0)) / -10.0
            dataStorage.attitude[1] = Double(getInt16(data, offset: 2)) / 10.0
            dataStorage.attitude[2] = Double(getInt16(data, offset: 4))
            
        case MSP_ANALOG: // 110
            guard check(7) else { return }
            dataStorage.voltage   = Double(data[0]) / 10.0
            dataStorage.mAhDrawn  = Int(getUInt16(data, offset: 1))
            dataStorage.rssi      = Int(getUInt16(data, offset: 3))
            dataStorage.amperage  = Double(getUInt16(data, offset: 5)) / 100.0
            
        case MSP_RC_TUNING: // 111
            guard check(8) else { return }
            var offset = 0
            dataStorage.rcRate    = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
            dataStorage.rcExpo    = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
            if dataStorage.apiVersion < "1.7.0" {
                dataStorage.rollPitchRate = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
                dataStorage.rollRate      = 0.0
                dataStorage.pitchRate     = 0.0
            } else {
                dataStorage.rollPitchRate = 0.0
                dataStorage.rollRate      = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
                dataStorage.pitchRate     = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
            }
            dataStorage.yawRate            = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
            dataStorage.dynamicThrottlePID = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
            dataStorage.throttleMid        = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
            dataStorage.throttleExpo       = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
            if dataStorage.apiVersion >= "1.7.0" {
                dataStorage.dynamicThrottleBreakpoint = Int(getUInt16(data, offset: offset))
                offset += 2
            } else {
                dataStorage.dynamicThrottleBreakpoint = 0
            }
            if dataStorage.apiVersion   >= "1.10.0" {
                dataStorage.yawExpo     = (Double(data[offset++]) / 100.0).roundWithDecimals(2)
            } else {
                dataStorage.yawExpo     = 0.0
            }
            
        case MSP_PID: // 112
            var needle = 0
            for i in 0 ..< data.count/3 {
                switch i {
                case 0, 1, 2, 3, 7, 8, 9:
                    dataStorage.PIDs[i][0] = Double(data[needle]) / 10
                    dataStorage.PIDs[i][1] = Double(data[needle+1]) / 1000
                    dataStorage.PIDs[i][2] = Double(data[needle+2])
                case 4:
                    dataStorage.PIDs[i][0] = Double(data[needle]) / 100
                    dataStorage.PIDs[i][1] = Double(data[needle+1]) / 100
                    dataStorage.PIDs[i][2] = Double(data[needle+2]) / 1000
                case 5, 6:
                    dataStorage.PIDs[i][0] = Double(data[needle]) / 10
                    dataStorage.PIDs[i][1] = Double(data[needle+1]) / 100
                    dataStorage.PIDs[i][2] = Double(data[needle+2]) / 1000
                default:
                    log("Unexpected data length while interpeting MSP_PID: \(i)")
                }
                needle += 3
            }
            
        case MSP_MISC: // 114
            guard check(18) else { return } // 22 pre 1.22.0
            var offset = 0
            dataStorage.midRc = Int(getInt16(data, offset: offset))
            offset += 2
            dataStorage.minThrottle = Int(getUInt16(data, offset: offset)) // 0-2000
            offset += 2
            dataStorage.maxThrottle = Int(getUInt16(data, offset: offset)) // 0-2000
            offset += 2
            dataStorage.minCommand = Int(getUInt16(data, offset: offset)) // 0-2000
            offset += 2
            dataStorage.failsafeThrottle = Int(getUInt16(data, offset: offset)) // 1000-2000
            offset += 2
            dataStorage.gpsType = Int(data[offset++])
            dataStorage.gpsBaudrate = Int(data[offset++])
            dataStorage.gpsUbxSbas = Int(getInt8(data, offset: offset++))
            dataStorage.multiwiiCurrentOutput = Int(data[offset++])
            dataStorage.rssiChannel = Int(data[offset++])
            dataStorage.placeHolder2 = Int(data[offset++])
            if dataStorage.apiVersion < "1.18.0" {
                dataStorage.magDeclination = Double(getInt16(data, offset: offset)) / 10 // -1800-1800
            } else {
                dataStorage.magDeclination = Double(getInt16(data, offset: offset)) / 100 // -18000-18000
            }
            offset += 2
            if dataStorage.apiVersion < "1.22.0" {
                dataStorage.vBatScale = Int(data[offset++]) // 10-200
                dataStorage.vBatMinCellVoltage = Int(data[offset++]) / 10 // 10-50
                dataStorage.vBatMaxCellVoltage = Int(data[offset++]) / 10 // 10-50
                dataStorage.vBatWarningCellVoltage = Int(data[offset++]) / 10 // 10-50
            }
            
        case MSP_BOXNAMES: // 116
            dataStorage.auxConfigNames = [] // empty array
            var buf: [UInt8] = []
            for byte in data {
                if byte == 0x3B { // ; (delimeter char)
                    let name: NSString = NSString(bytes: &buf, length: buf.count, encoding: String.Encoding.utf8.rawValue)!
                    dataStorage.auxConfigNames.append(String(name))
                    buf = [] // reset for next name
                } else {
                    buf.append(byte)
                }
            }
            
        case MSP_PIDNAMES: // 117
            dataStorage.PIDNames = [] // empty array
            var buf: [UInt8] = []
            for byte in data {
                if byte == 0x3B { // ; (delimeter char)
                    let name: NSString = NSString(bytes: &buf, length: buf.count, encoding: String.Encoding.utf8.rawValue)!
                    dataStorage.PIDNames.append(String(name))
                    buf = [] // reset for next name
                } else {
                    buf.append(byte)
                }
            }
            
        case MSP_BOXIDS: // 119
            dataStorage.auxConfigIDs = []
            for boxID in data {
                dataStorage.auxConfigIDs.append(Int(boxID))
            }
            
        case MSP_SET_PID: // 202
            log("MSP_SET_PID received")
            
        case MSP_SET_RC_TUNING: // 204
            log("MSP_SET_RC_TUNING received")
            
        case MSP_ACC_CALIBRATION: // 205
            log("MSP_ACC_CALIBRATION received")
            
        case MSP_MAG_CALIBRATION: // 206
            log("MSP_MAG_CALIBRATION received")
            
        case MSP_SET_MISC: // 207
            log("MSP_SET_MISC received")
            
        case MSP_RESET_CONF: // 208
            log("MSP_RESET_CONF received")
            
        case MSP_SELECT_SETTING: // 210
            log("MSP_SELECT_SETTING received")
            
        case MSP_SET_ACC_TRIM: // 239
            log("MSP_SET_ACC_TRIM received")
            
        case MSP_ACC_TRIM: // 240
            guard check(4) else { return }
            dataStorage.accTrimPitch = Int(getInt16(data, offset: 0))
            dataStorage.accTrimRoll = Int(getInt16(data, offset: 2))
            
        case MSP_EEPROM_WRITE: // 250
            log("Data saved to eeprom!")
            MessageView.show("EEPROM saved")

        default:
            log(.Error, "Message has unknown MSP command: \(code)")
        }
        
        // send message to subscribers of this code
        if subscribers[code] != nil {
            for sub in subscribers[code]! {
                sub.mspUpdated(code)
            }
        }
        
        // call callbacks
        for i in (0 ..< callbacks.count).reversed() {
            let item = callbacks[i]
            if item.code == code {
                item.callback()
                callbacks.remove(at: i)
            }
        }
    }
    
    func crunch(_ code: Int) -> [UInt8] {
        var buffer: [UInt8] = []
        switch code {
            
        case MSP_SET_FEATURE: // 37
            buffer.append(UInt32(dataStorage.BFFeatures).specificByte(0))
            buffer.append(UInt32(dataStorage.BFFeatures).specificByte(1))
            buffer.append(UInt32(dataStorage.BFFeatures).specificByte(2))
            buffer.append(UInt32(dataStorage.BFFeatures).specificByte(3))
            
        case MSP_SET_BOARD_ALIGNMENT: // 39
            buffer.append(Int16(dataStorage.boardAlignRoll).specificByte(0))
            buffer.append(Int16(dataStorage.boardAlignRoll).specificByte(1))
            buffer.append(Int16(dataStorage.boardAlignPitch).specificByte(0))
            buffer.append(Int16(dataStorage.boardAlignPitch).specificByte(1))
            buffer.append(Int16(dataStorage.boardAlignYaw).specificByte(0))
            buffer.append(Int16(dataStorage.boardAlignYaw).specificByte(1))
            
        case MSP_SET_MIXER: // 43
            buffer.append(UInt8(dataStorage.mixerConfiguration) + 1)
            
        case MSP_SET_RX_CONFIG: // 45
            buffer.append(UInt8(dataStorage.serialRXType))
            buffer.append(dataStorage.stickMax.lowByte)
            buffer.append(dataStorage.stickMax.highByte)
            buffer.append(dataStorage.stickCenter.lowByte)
            buffer.append(dataStorage.stickCenter.highByte)
            buffer.append(dataStorage.stickMin.lowByte)
            buffer.append(dataStorage.stickMin.highByte)
            buffer.append(UInt8(dataStorage.satBind))
            buffer.append(dataStorage.rxMinuSec.lowByte)
            buffer.append(dataStorage.rxMinuSec.highByte)
            buffer.append(dataStorage.rxMaxuSec.lowByte)
            buffer.append(dataStorage.rxMaxuSec.highByte)
            
        case MSP_SET_CF_SERIAL_CONFIG: // 55
            if dataStorage.apiVersion >= "1.6.0" {
                for port in dataStorage.serialPorts {
                    buffer.append(UInt8(port.identifier))
                    
                    var mask = 0
                    for function in port.functions {
                        mask |= 1 << function.rawValue
                    }
                    
                    buffer.append(mask.lowByte)
                    buffer.append(mask.highByte)
                    buffer.append(UInt8(port.MSP_baudrate.rawValue))
                    buffer.append(UInt8(port.GPS_baudrate.rawValue))
                    buffer.append(UInt8(port.TELEMETRY_baudrate.rawValue))
                    buffer.append(UInt8(port.BLACKBOX_baudrate.rawValue))
                }
            }
            
        case MSP_SET_PID_CONTROLLER: // 60
            buffer = [UInt8(dataStorage.PIDController)]
            
        case MSP_SET_ARMING_CONFIG: // 62
            buffer.append(UInt8(dataStorage.autoDisarmDelay))
            buffer.append(UInt8(dataStorage.disarmKillsSwitch ? 1 : 0))
            
        case MSP_SET_RX_MAP: // 65
            for i in dataStorage.RC_MAP {
                buffer.append(UInt8(i))
            }
            
        case MSP_SET_BF_CONFIG: // 67
            buffer.append(dataStorage.mixerConfiguration.specificByte(0) + 1)
            buffer.append(UInt32(dataStorage.BFFeatures).specificByte(0))
            buffer.append(UInt32(dataStorage.BFFeatures).specificByte(1))
            buffer.append(UInt32(dataStorage.BFFeatures).specificByte(2))
            buffer.append(UInt32(dataStorage.BFFeatures).specificByte(3))
            buffer.append(dataStorage.serialRXType.specificByte(0))
            buffer.append(Int16(dataStorage.boardAlignRoll).specificByte(0))
            buffer.append(Int16(dataStorage.boardAlignRoll).specificByte(1))
            buffer.append(Int16(dataStorage.boardAlignPitch).specificByte(0))
            buffer.append(Int16(dataStorage.boardAlignPitch).specificByte(1))
            buffer.append(Int16(dataStorage.boardAlignYaw).specificByte(0))
            buffer.append(Int16(dataStorage.boardAlignYaw).specificByte(1))
            buffer.append(Int16(dataStorage.currentScale).specificByte(0))
            buffer.append(Int16(dataStorage.currentScale).specificByte(1))
            buffer.append(dataStorage.currentOffset.specificByte(0))
            buffer.append(dataStorage.currentOffset.specificByte(1))
            
        case MSP_SET_LOOP_TIME: // 74
            buffer.append(Int16(dataStorage.loopTime).lowByte)
            buffer.append(Int16(dataStorage.loopTime).highByte)
            
        case MSP_SET_RC_TUNING: // 111
            buffer.append(UInt8(dataStorage.rcRate * 100.0))
            buffer.append(UInt8(dataStorage.rcExpo * 100.0))
            if dataStorage.apiVersion < "1.7.0" {
                buffer.append(UInt8(dataStorage.rollRate * 100.0)) // roll & pitch rate in one
            } else {
                buffer.append(UInt8(dataStorage.rollRate * 100.0))
                buffer.append(UInt8(dataStorage.pitchRate * 100.0))
            }
            buffer.append(UInt8(dataStorage.yawRate * 100.0))
            buffer.append(UInt8(dataStorage.dynamicThrottlePID * 100.0))
            buffer.append(UInt8(dataStorage.throttleMid * 100.0))
            buffer.append(UInt8(dataStorage.throttleExpo * 100.0))
            if dataStorage.apiVersion >= "1.7.0" {
                buffer.append(UInt8(dataStorage.dynamicThrottleBreakpoint & 255))
                buffer.append(UInt8(dataStorage.dynamicThrottleBreakpoint >> 8))
            }
            if dataStorage.apiVersion >= "1.10.0" {
                buffer.append(UInt8(dataStorage.yawExpo * 100.0))
            }

        case MSP_SET_PID: // 202
            for (i, triplet) in dataStorage.PIDs.enumerated() {
                switch i {
                case 0, 1, 2, 3, 7, 9:
                    buffer.append(UInt8(triplet[0] * 10.0))
                    buffer.append(UInt8(triplet[1] * 1000.0))
                    buffer.append(UInt8(triplet[2]))
                case 4:
                    buffer.append(UInt8(triplet[0] * 100.0))
                    buffer.append(UInt8(triplet[1] * 100.0))
                    buffer.append(UInt8(0))
                case 5, 6:
                    buffer.append(UInt8(triplet[0] * 10.0))
                    buffer.append(UInt8(triplet[1] * 100.0))
                    buffer.append(UInt8(triplet[2] * 1000.0))
                case 8:
                    buffer.append(UInt8(triplet[0] * 10.0))
                    buffer.append(UInt8(0))
                    buffer.append(UInt8(0))
                default:
                    log(.Error, "Unexpected data length \(i) while generating data for MSP_SET_PID")
                }
            }
            
        case MSP_SET_MISC: // 207
            buffer.append(dataStorage.midRc.lowByte)
            buffer.append(dataStorage.midRc.highByte)
            buffer.append(dataStorage.minThrottle.lowByte)
            buffer.append(dataStorage.minThrottle.highByte)
            buffer.append(dataStorage.maxThrottle.lowByte)
            buffer.append(dataStorage.maxThrottle.highByte)
            buffer.append(dataStorage.minCommand.lowByte)
            buffer.append(dataStorage.minCommand.highByte)
            buffer.append(dataStorage.failsafeThrottle.lowByte)
            buffer.append(dataStorage.failsafeThrottle.highByte)
            buffer.append(UInt8(dataStorage.gpsType))
            buffer.append(UInt8(dataStorage.gpsBaudrate))
            buffer.append(UInt8(dataStorage.gpsUbxSbas))
            buffer.append(UInt8(dataStorage.multiwiiCurrentOutput))
            buffer.append(UInt8(dataStorage.rssiChannel))
            buffer.append(UInt8(dataStorage.placeHolder2))
            if dataStorage.apiVersion < "1.18.0" {
                buffer.append(Int16(round(dataStorage.magDeclination * 10)).lowByte)
                buffer.append(Int16(round(dataStorage.magDeclination * 10)).highByte)
            } else {
                buffer.append(Int16(round(dataStorage.magDeclination * 100)).lowByte)
                buffer.append(Int16(round(dataStorage.magDeclination * 100)).highByte)
            }
            if dataStorage.apiVersion < "1.22.0" {
                buffer.append(UInt8(dataStorage.vBatScale))
                buffer.append(UInt8(dataStorage.vBatMinCellVoltage * 10))
                buffer.append(UInt8(dataStorage.vBatMaxCellVoltage * 10))
                buffer.append(UInt8(dataStorage.vBatWarningCellVoltage * 10))
            }
            
        case MSP_SELECT_SETTING: // 210
            buffer.append(UInt8(dataStorage.profile))
            
        case MSP_SET_ACC_TRIM: // 239
            buffer.append(Int16(dataStorage.accTrimPitch).lowByte)
            buffer.append(Int16(dataStorage.accTrimPitch).highByte)
            buffer.append(Int16(dataStorage.accTrimRoll).lowByte)
            buffer.append(Int16(dataStorage.accTrimRoll).highByte)
            
        default:
            log(.Error, "Unknown MSP command sent received to crunch: \(code)")
        }
        
        return buffer
    }
    
    func sendModeRanges(callback endCallback: ((Void) -> Void)?) {
        var index = 0

        func sendNextModeRange() {
            var modeRange = dataStorage.modeRanges[index],
                buffer: [UInt8] = []
            
            buffer.append(UInt8(index++))
            buffer.append(UInt8(modeRange.identifier))
            buffer.append(UInt8(modeRange.auxChannelIndex))
            buffer.append(UInt8((modeRange.range.start - 900) / 25))
            buffer.append(UInt8((modeRange.range.end - 900) / 25))
            
            sendMSP(MSP_SET_MODE_RANGE, bytes: buffer, callback: index == dataStorage.modeRanges.count ? endCallback : sendNextModeRange)
        }
        
        if dataStorage.modeRanges.isEmpty {
            endCallback?()
        } else {
            sendNextModeRange()
        }
    }
    
    func sendMSP(_ code: Int, bytes: [UInt8]?, callback: ((Void) -> Void)?) {
        // only send msp codes if we'll get the reply
        guard bluetoothSerial.delegate as AnyObject? === self && !cliActive else { return }
        
        // add callback
        if callback != nil {
            callbacks.append((code, callback!))
        }
        
        // send message with bytes [$, M, <, data length, code, [data], checksum
        // with checksum being the XOR of the data legth, code, and all data bytes

        let codeByte = UInt8(code)
        let length = UInt8(bytes == nil ? 0 : bytes!.count)
        var checksum = UInt8(codeByte ^ length)
        if length > 0 { for byte in bytes! { checksum ^= byte }}
        var message: [UInt8] = [36, 77, 60, length, codeByte]
        if length > 0 { message += bytes! }
        message.append(checksum)
        
        bluetoothSerial.sendBytesToDevice(message)
    }
    
    func sendMSP(_ code: Int, bytes: [UInt8]?) {
        sendMSP(code, bytes:  bytes, callback: nil)
    }
    
    func sendMSP(_ code: Int) {
        sendMSP(code, bytes: nil, callback: nil)
    }
    
    func sendMSP(_ code: Int, callback: @escaping ((Void) -> Void)) {
        sendMSP(code, bytes: nil, callback: callback)
    }
    
    /// Codes are NOT sent sequentially
    func sendMSP(_ codes: [Int]) {
        for code in codes {
            sendMSP(code, bytes: nil, callback: nil)
        }
    }
    
    /// Codes are sent sequentially
    func sendMSP(_ codes: [Int], callback: @escaping ((Void) -> Void)) {
        var i = 0
        func sendNext() {
            if i == codes.endIndex {
                callback()
                return
            }
            sendMSP(codes[i++], callback: sendNext)
        }
        
        sendNext()
    }
    
    func crunchAndSendMSP(_ code: Int) {
        sendMSP(code, bytes: crunch(code), callback: nil)
    }
    
    func crunchAndSendMSP(_ code: Int, callback: @escaping ((Void) -> Void)) {
        sendMSP(code, bytes: crunch(code), callback: callback)
    }
    
    /// Codes are sent sequentially
    func crunchAndSendMSP(_ codes: [Int], callback: @escaping ((Void) -> Void)) {
        var i = 0
        func sendNext() {
            if i == codes.endIndex {
                callback()
                return
            }
            crunchAndSendMSP(codes[i++], callback: sendNext)
        }
        
        sendNext()
    }

    
    func reset() {
        // called when finished interpreting MSP or
        // when the serial port is closed
        state = 0
        messageLengthReceived = 0
        messageData = []
    }
    
    func didDisconnect() {
        reset()
        //if callbacks.count > 0 {
        //    log(.Warn, "\(callbacks.count) callbacks remained after disconnecting")
            callbacks = []
        //}
    }
    
    func addSubscriber(_ newSubscriber: MSPUpdateSubscriber, forCodes codes: [Int]) {
        for code in codes {
            if let set = subscribers[code] {
                if set.containsObject(newSubscriber) {
                    log(.Error, "MSPInterpreter: Tried to subscribe object to MSP code it was already subscribed to")
                } else {
                    set.addObject(newSubscriber)
                }
            } else {
                subscribers[code] = WeakSet<MSPUpdateSubscriber>(newSubscriber)
            }
        }
    }
    
    func removeSubscriber(_ subscriber: MSPUpdateSubscriber, forCodes codes: [Int]) {
        for code in codes {
            if let set = subscribers[code] {
                if set.containsObject(subscriber) {
                    set.removeObject(subscriber)
                } else {
                    log(.Error, "MSPInterpreter: Tried to unsubscribe object from code it was not subscribed to")
                }
            } else {
                log(.Error, "MSPInterpreter: Tried to unsubscribe object from code it was not subscribed to")
            }
        }
    }
}
