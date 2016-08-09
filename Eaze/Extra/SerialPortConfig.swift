//
//  SerialPort.swift
//  CleanflightMobile
//
//  Created by Alex on 03-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

struct SerialPortConfig {
    
    private static let portIdentifierToNameMapping = [0: "UART1", 1: "UART2", 2: "UART3", 3: "UART4", 20: "USB VCP", 30: "SOFTSERIAL1", 31: "SOFTSERIAL2"]
    
    var identifier = 0
    var name: String { get { return SerialPortConfig.portIdentifierToNameMapping[identifier] ?? "Unavailable" }}
    var functions: [SerialPortFunction] = []
    
    var MSP_baudrate = Baudrate.Auto
    var GPS_baudrate = Baudrate.Auto
    var TELEMETRY_baudrate = Baudrate.Auto
    var BLACKBOX_baudrate = Baudrate.Auto
}


enum SerialPortFunction: Int {
    // TELM_MSP only < 1.15.0, TELM_LTM only >= 1.15.0 (id TELM_LTM == id TELM_MSP, TELM_LTM replaced TELM_MSP), MAVLINK only >= 1.18.0
    case MSP, GPS, TELEMETRY_FRSKY, TELEMETRY_HOTT, TELEMETRY_MSP_LTM, TELEMETRY_SMARTPORT, RX_SERIAL, BLACKBOX, TELEMETRY_MAVLINK
    
    static var all: [SerialPortFunction] {
        get {
            return [MSP, GPS, TELEMETRY_FRSKY, TELEMETRY_HOTT, TELEMETRY_MSP_LTM, TELEMETRY_SMARTPORT, RX_SERIAL, BLACKBOX, TELEMETRY_MAVLINK]
        }
    }
}


enum Baudrate: Int {
    case Auto, B9600, B19200, B38400, B57600, B115200, B230400, B250000
    
    var name: String {
        get {
            return ["AUTO", "9600", "19200", "38400", "57600", "115200", "230400", "250000"][rawValue]
        }
    }
    
    var intValue: Int {
        get {
            return [0, 9600, 19200, 38400, 57600, 115200, 230400, 250000][rawValue]
        }
    }
    
    static var all: [Baudrate] {
        get {
            return [Auto, B9600, B19200, B38400, B57600, B115200, B230400, B250000]
        }
    }
}