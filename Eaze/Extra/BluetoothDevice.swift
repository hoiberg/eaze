//
//  BluetoothDevice.swift
//  CleanflightMobile
//
//  Created by Alex on 12-03-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothDevice: NSObject {
    
    static var devices = BluetoothDevice.loadBluetoothDevices()
    
    var name: String
    var UUID: NSUUID
    var autoConnect: Bool // not yet used
    var writeWithResponse: Bool
    
    init(name: String, UUID: NSUUID, autoConnect: Bool, writeWithResponse: Bool) {
        self.name = name
        self.UUID = UUID
        self.autoConnect = autoConnect
        self.writeWithResponse = writeWithResponse
    }
    
    private class func loadBluetoothDevices() -> [BluetoothDevice] {
        let fileManager = NSFileManager.defaultManager(),
                docPath = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!,
               filePath = docPath.URLByAppendingPathComponent("BluetoothDevices.json")
        
        if !fileManager.fileExistsAtPath(filePath.path!) {
            return []
        }
        
        do {
            let json = try VJson.createJsonHierarchy(filePath)
            //let version = Version(string: json["version"].stringValue ?? "1.0.0") <- not yet needed but "version" is there!
            if let subs = json["bluetoothdevices"].arrayValue {
                var devices: [BluetoothDevice] = []
                for sub in subs {
                    devices.append(BluetoothDevice(name: sub["name"].stringValue!,
                                                   UUID: NSUUID(UUIDString: sub["uuid"].stringValue!)!,
                                            autoConnect: sub["autoconnect"].boolValue!,
                                      writeWithResponse: sub["writewithresponse"].boolValue!))
                }
                
                return devices.sort() { $0.name < $1.name }
            } else {
                return []
            }
        } catch {
            print("Failed to BluetoothDevices at url: \(filePath), error: \(error)")
            return []
        }
    }
    
    class func saveDevices() {
        let json = VJson.createJsonHierarchy()
        json["version"].stringValue = "1.0.0"
        for (index, device) in devices.enumerate() {
            let sub = json["bluetoothdevices"][index]
            sub["name"].stringValue = device.name
            sub["uuid"].stringValue = device.UUID.UUIDString
            sub["autoconnect"].boolValue = device.autoConnect
            sub["writewithresponse"].boolValue = device.writeWithResponse
        }
        
        let fileManager = NSFileManager.defaultManager(),
                docPath = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!,
               filePath = docPath.URLByAppendingPathComponent("BluetoothDevices.json")

        json.save(filePath)
    }
    
    class func deviceWithUUID(uuid: NSUUID) -> BluetoothDevice? {
        return devices.find { $0.UUID.isEqual(uuid) }
    }
}
