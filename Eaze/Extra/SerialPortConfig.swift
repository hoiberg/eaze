//
//  SerialPort.swift
//  CleanflightMobile
//
//  Created by Alex on 03-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

class SerialPortConfig: Copyable {
    
    fileprivate static let portIdentifierToNameMapping = [0: "UART1", 1: "UART2", 2: "UART3", 3: "UART4", 20: "USB VCP", 30: "SOFTSERIAL1", 31: "SOFTSERIAL2"]
    
    var identifier = 0
    var name: String { get { return SerialPortConfig.portIdentifierToNameMapping[identifier] ?? "Unavailable" }}
    var functions: [SerialPortFunction] = []
    
    var MSP_baudrate = Baudrate.auto
    var GPS_baudrate = Baudrate.auto
    var TELEMETRY_baudrate = Baudrate.auto
    var BLACKBOX_baudrate = Baudrate.auto
    
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
    case msp,
         gps,
         telemetry_FRSKY,
         telemetry_HOTT,
         telemetry_MSP_LTM, // MSP < 1.15.0, replaced by LTM >= 1.15.0, same ID
         telemetry_SMARTPORT,
         rx_SERIAL, blackbox,
         telemetry_MAVLINK // >= 1.18.0
    
    static var all: [SerialPortFunction] {
        return [self.msp, gps, telemetry_FRSKY, telemetry_HOTT, telemetry_MSP_LTM, telemetry_SMARTPORT, rx_SERIAL, blackbox, telemetry_MAVLINK]
    }
}

//SerialPortFunction.RawValue


enum Baudrate: Int {
    case auto, b9600, b19200, b38400, b57600, b115200, b230400, b250000
    
    var name: String {
        return ["AUTO", "9600", "19200", "38400", "57600", "115200", "230400", "250000"][rawValue]
    }
    
    var intValue: Int {
        return [0, 9600, 19200, 38400, 57600, 115200, 230400, 250000][rawValue]
    }
    
    static var all: [Baudrate] {
        return [auto, b9600, b19200, b38400, b57600, b115200, b230400, b250000]
    }
}
