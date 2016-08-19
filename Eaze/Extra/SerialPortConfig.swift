//
//  SerialPort.swift
//  CleanflightMobile
//
//  Created by Alex on 03-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

class SerialPortConfig: Copyable {
    
    private static let portIdentifierToNameMapping = [0: "UART1", 1: "UART2", 2: "UART3", 3: "UART4", 20: "USB VCP", 30: "SOFTSERIAL1", 31: "SOFTSERIAL2"]
    
    var identifier = 0
    var name: String { get { return SerialPortConfig.portIdentifierToNameMapping[identifier] ?? "Unavailable" }}
    var functions: [SerialPortFunction] = []
    
    var MSP_baudrate = Baudrate.Auto
    var GPS_baudrate = Baudrate.Auto
    var TELEMETRY_baudrate = Baudrate.Auto
    var BLACKBOX_baudrate = Baudrate.Auto
    
    init() {}
    
    required init(copy: SerialPortConfig) {
        identifier = copy.identifier
        functions = copy.functions
        MSP_baudrate = copy.MSP_baudrate
        GPS_baudrate = copy.GPS_baudrate
        TELEMETRY_baudrate = copy.TELEMETRY_baudrate
        BLACKBOX_baudrate = copy.BLACKBOX_baudrate
    }
}


enum SerialPortFunction: Int {
    case MSP,
         GPS,
         TELEMETRY_FRSKY,
         TELEMETRY_HOTT,
         TELEMETRY_MSP_LTM, // MSP < 1.15.0, replaced by LTM >= 1.15.0, same ID
         TELEMETRY_SMARTPORT,
         RX_SERIAL, BLACKBOX,
         TELEMETRY_MAVLINK // >= 1.18.0
    
    static var all: [SerialPortFunction] {
        return [MSP, GPS, TELEMETRY_FRSKY, TELEMETRY_HOTT, TELEMETRY_MSP_LTM, TELEMETRY_SMARTPORT, RX_SERIAL, BLACKBOX, TELEMETRY_MAVLINK]
    }
}

//SerialPortFunction.RawValue


enum Baudrate: Int {
    case Auto, B9600, B19200, B38400, B57600, B115200, B230400, B250000
    
    var name: String {
        return ["AUTO", "9600", "19200", "38400", "57600", "115200", "230400", "250000"][rawValue]
    }
    
    var intValue: Int {
        return [0, 9600, 19200, 38400, 57600, 115200, 230400, 250000][rawValue]
    }
    
    static var all: [Baudrate] {
        return [Auto, B9600, B19200, B38400, B57600, B115200, B230400, B250000]
    }
}