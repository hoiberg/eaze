//
//  BluetoothDevice.swift
//  CleanflightMobile
//
//  Created by Alex on 12-03-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit
import CoreBluetooth

final class BluetoothDevice: NSObject {
    
    static var devices = BluetoothDevice.loadBluetoothDevices()
    
    var name: String
    var UUID: Foundation.UUID
    var autoConnect: Bool // not yet used
    var writeWithResponse: Bool
    
    init(name: String, UUID: Foundation.UUID, autoConnect: Bool, writeWithResponse: Bool) {
        self.name = name
        self.UUID = UUID
        self.autoConnect = autoConnect
        self.writeWithResponse = writeWithResponse
    }
    
    fileprivate class func loadBluetoothDevices() -> [BluetoothDevice] {
        let fileManager = FileManager.default,
                docPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!,
               filePath = docPath.appendingPathComponent("BluetoothDevices.json")
        
        if !fileManager.fileExists(atPath: filePath.path) {
            return []
        }
        
        do {
            let json = try VJson.parse(file: filePath)
            //let version = Version(string: json["version"].stringValue ?? "1.0.0") <- not yet needed but "version" is there!
            if let subs = json["bluetoothdevices"].arrayValue {
                var devices: [BluetoothDevice] = []
                for sub in subs {
                    devices.append(BluetoothDevice(name: sub["name"].stringValue!,
                                                   UUID: Foundation.UUID(uuidString: sub["uuid"].stringValue!)!,
                                            autoConnect: sub["autoconnect"].boolValue!,
                                      writeWithResponse: sub["writewithresponse"].boolValue!))
                }
                
                return devices.sorted() { $0.name < $1.name }
            } else {
                return []
            }
        } catch {
            log(.Error, "Failed to BluetoothDevices at url: \(filePath), error: \(error)")
            return []
        }
    }
    
    class func saveDevices() {
        let json = VJson()
        json["version"].stringValue = "1.0.0"
        for (index, device) in devices.enumerated() {
            let sub = json["bluetoothdevices"][index]
            sub["name"].stringValue = device.name
            sub["uuid"].stringValue = device.UUID.uuidString
            sub["autoconnect"].boolValue = device.autoConnect
            sub["writewithresponse"].boolValue = device.writeWithResponse
        }
        
        let fileManager = FileManager.default,
                docPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!,
               filePath = docPath.appendingPathComponent("BluetoothDevices.json")

        json.save(to: filePath)
    }
    
    class func deviceWithUUID(_ uuid: Foundation.UUID) -> BluetoothDevice? {
        return devices.find { ($0.UUID == uuid) }
    }
}
