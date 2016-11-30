//
//  BluetoothSerial.swift
//  For communication with HM10 BLE UART modules
//
//  Created by Alex on 09-08-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//
//  HM10's service UUID is FFE0, the characteristic we need is FFE1
//  Some require WriteWithResponse, others WithoutResponse..
//
//  RSSI goes from about -40 to -100 (which is when it looses signal)
//
//  How viewcontrollers should implement communication with the FC:
//  1) In viewDidLoad, subscribe to the MSP codes you're going to send (at least those you need the reaction of..)
//  2) Subscribe to BluetoothSerialDidConnectNotification (*)
//      in whose selector you send MSP codes (if isBeingShown) and enable buttons etc
//  3) Subscribe to BluetoothSerialDidDisconnectNotification
//      in whose selector you disable buttons etc
//  4) Implement the MSPSubscriber protocol (if neccesary) and put a switch statement in there
//      in which you update the UI and other stuff according to the code (data) received
//  5) In either viewWillAppear, viewDidLoad or willBecomePrimary (depending on your view)
//      a) if already connected, send MSP codes and enable buttons etc
//      b) if not connected, disable buttons etc
//
//  If the viewController sends continous msp data requests, it needs to start the timer in
//  viewWillAppear, AppDidBecomeActive and serialDidOpen (the latter two only if isBeingShown)
//  It then stops the timer in viewWillDisappear, AppWillResignActive and serialDidClose (again, the latter two only if isBeingShown).
//
//  Note: yes, you can use sendMSP(code, callback), but its purpose is for when timing is important (calibration, reset etc), not UI updates.
//  *: Just in case, this might be removed in future versions if deemed unneccesary - the actual connecting should only happen 
//     while the Dashboard tab is active.

import UIKit
import CoreBluetooth
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

extension Notification.Name {
    enum Serial {
        static let willAutoConnect = Notification.Name("serialWillAutoConnect")
        static let didConnect = Notification.Name("serialDidConnect")
        static let didFailToConnect = Notification.Name("serialDidFailToConnect")
        static let didDisconnect = Notification.Name("serialDidDisconnect")
        static let didDiscoverNewPeripheral = Notification.Name("serialDidDiscoverNewPeripheral")
        static let didUpdateState = Notification.Name("serialDidUpdateState")
        static let didStopScanning = Notification.Name("serialDidStopScanning")
        static let opened = didConnect
        static let closed = didDisconnect
    }
}

protocol BluetoothSerialDelegate {
    func serialPortReceivedData(_ data: Data)
}

enum BluetoothSerialState {
    case poweredOn, poweredOff
}

final class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Variables
    
    /// The object that will be notified of new data arriving
    var delegate: BluetoothSerialDelegate?
    
    /// The CBCentralManager this bluetooth serial handler uses for communication
    var centralManager: CBCentralManager!
    
    /// The peripheral we are currently trying to connect to/trying to verify (nil if none)
    var pendingPeripheral: CBPeripheral?
    
    /// The connected peripheral (nil if none is connected). This device is ready to receive MSP/CLI commands
    var connectedPeripheral: CBPeripheral?
    
    /// The peripheral that was suddenly disconnected, and we're trying to reconnect to
    var reconnectingPeripheral: CBPeripheral?
    
    /// The characteristic we need to write to
    fileprivate weak var writeCharacteristic: CBCharacteristic?
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var discoveredPeripherals: [(peripheral: CBPeripheral?, RSSI: Float)] = []
    
    /// The state of the bluetooth manager (use this to determine whether it is on or off or disabled etc)
    var state: BluetoothSerialState {
        return centralManager.state == .poweredOn ? .poweredOn : .poweredOff
    }
    
    /// Whether we're scanning for devices right now
    var isScanning: Bool {
        return centralManager.isScanning
    }
    
    /// Whether we're currently trying to connect to/verify a peripheral
    var isConnecting: Bool {
        return pendingPeripheral != nil
    }
    
    /// Whether the serial port is open and ready to send or receive data
    var isConnected: Bool {
        return connectedPeripheral != nil
    }
    
    /// Whether we're trying to reconnect a disconnected peripheral
    var isReconnecting: Bool {
        return reconnectingPeripheral != nil
    }
    
    /// WriteType we use to write data to the peripheral
    var writeType = CBCharacteristicWriteType.withResponse
    
    /// Function called the next time some data is received (to be used for testing the connection)
    fileprivate var callbackOnReceive: ((Data) -> Void)?
    
    /// Function called when RSSI is read
    fileprivate var rssiCallback: ((NSNumber) -> Void)?
    
    /// Whether to expect a disconnection
    fileprivate var forceDisconnect = false
    
    
    // MARK: - Functions
    
    /// Initializor
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Start scanning for peripherals
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        log("Start scanning")
        
        discoveredPeripherals = []
        
        // search for devices with correct service UUID, and allow duplicates for RSSI update (but only if it is needed for auto connecting new peripherals)
        let serviceUUIDs = [CBUUID(string: "FFE0")],
            scanOptions = [CBCentralManagerScanOptionAllowDuplicatesKey: userDefaults.bool(forKey: DefaultsAutoConnectNewKey)]
        centralManager.scanForPeripherals( withServices: serviceUUIDs, options: scanOptions)
        
        // maybe the peripheral is still connected
        for peripheral in centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs) {
            evaluatePeripheral(peripheral, RSSI: nil)
        }
    }
    
    /// Try to connect to the given peripheral
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        guard centralManager.state == .poweredOn else { return }
        log("Connecting to peripheral \(peripheral.name ?? "Unknown")")
        
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
        delay(10) {
            // timeout
            guard self.isConnecting else { return }
            log("Connection timeout")
            self.disconnect()
            notificationCenter.post(name: Notification.Name.Serial.didFailToConnect, object: nil)
        }
    }
    
    /// Stop scanning for new peripherals
    func stopScan() {
        guard centralManager.state == .poweredOn else { return }
        log("Stopped scanning")
        
        centralManager.stopScan()
        notificationCenter.post(name: Notification.Name.Serial.didStopScanning, object: nil)
    }
    
    /// Disconnect from the connected peripheral, the pending preipheral, or the reconnecting peripheral
    func disconnect() {
        guard centralManager.state == .poweredOn else { return }
        log("Disconnecting")
        forceDisconnect = true // avoid auto reconnect
        
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p) // didDisconnect will be called, no need to do more stuff in here
        } else if let p = pendingPeripheral {
            centralManager.cancelPeripheralConnection(p) // didFailToConnect or didDisconnect will be called
        } else if let p = reconnectingPeripheral {
            centralManager.cancelPeripheralConnection(p) // didFailToConnect will be called
        }
    }
    
    /// Send an array of raw bytes to the HM10
    func sendBytesToDevice(_ bytes: [UInt8]) {
        guard isConnected else { return }
                
        let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    /// Send a string to the HM10 (only supports 8-bit UTF8 encoding)
    func sendStringToDevice(_ string: String) {
        guard isConnected else { return }
        
        if let data = string.data(using: String.Encoding.utf8) {
            connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
        }
    }
    
    /// Send a NSData object to the HM10
    func sendDataToDevice(_ data: Data) {
        guard isConnected else { return }
        
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    /// Read RSSI
    func readRSSI(_ callback: @escaping (NSNumber) -> Void) {
        guard isConnected else { return }
        rssiCallback = callback
        connectedPeripheral!.readRSSI()
    }
    
    fileprivate func evaluatePeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        var isKnown = false,
            autoConnect = false
        
        // check if we already have met this device before
        if BluetoothDevice.deviceWithUUID(peripheral.identifier) != nil {
            isKnown = true
        }
        
        // we do this before checking for duplicates for RSSI updates
        if userDefaults.bool(forKey: DefaultsAutoConnectNewKey) && RSSI?.intValue > -70 && !isKnown {
            stopScan()
            connectToPeripheral(peripheral)
            notificationCenter.post(name: Notification.Name.Serial.willAutoConnect, object: nil)
            autoConnect = true
        }
        
        // stop if it is a duplicate
        for exisiting in discoveredPeripherals {
            if exisiting.peripheral?.identifier == peripheral.identifier { return }
        }
        
        // auto connect if we already know this device
        if userDefaults.bool(forKey: DefaultsAutoConnectOldKey) && isKnown {
            stopScan()
            connectToPeripheral(peripheral)
            notificationCenter.post(name: Notification.Name.Serial.willAutoConnect, object: nil)
            autoConnect = true
        }
        
        // add to the array, next sort & reload & send notification
        discoveredPeripherals.append((peripheral: peripheral, RSSI: RSSI?.floatValue ?? -100.0))
        discoveredPeripherals.sort { $0.RSSI < $1.RSSI }
        
        notificationCenter.post(name: Notification.Name.Serial.didDiscoverNewPeripheral, object: nil, userInfo: ["WillAutoConnect": autoConnect])
    }
    
    
    // MARK: - CBCentralManagerDelegate functions
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        evaluatePeripheral(peripheral, RSSI: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        
        // switch from reconnecting to pending  if neccesary
        if reconnectingPeripheral != nil {
            reconnectingPeripheral = nil
            pendingPeripheral = peripheral
        }
        
        // Okay, the peripheral is connected but we're not ready yet!
        // First get the 0xFFE0 service
        // Then get the characteristics 0xFFE1 of this service
        // Subscribe to it, keep a reference to it (for writing later on)
        // And then we're ready for communication
        // If this does not happen within 10 seconds, we've failed and have to find another device..
        
        peripheral.discoverServices([CBUUID(string: "FFE0")])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let wasConnected = isConnected
        
        pendingPeripheral = nil
        connectedPeripheral = nil
        writeCharacteristic = nil
        callbackOnReceive = nil
        msp.didDisconnect() // reset & clear callbacks
        
        log("Disconnected")
        MessageView.show("Disconnected")
        notificationCenter.post(name: Notification.Name.Serial.didDisconnect, object: nil)
        
        if forceDisconnect || !wasConnected {
            // re-enable sleep
            UIApplication.shared.isIdleTimerDisabled = false
            forceDisconnect = false
        } else {
            // reconnect
            reconnectingPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
            
            // switch back to homeviewcontroller
            let tab = UIApplication.shared.windows.first?.rootViewController as! UITabBarController
            tab.selectedIndex = 0
            
            // now that the homeviewcontroller is visible, send the notification
            notificationCenter.post(name: Notification.Name.Serial.willAutoConnect, object: nil)
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("Failed to connect")
        
        pendingPeripheral = nil
        reconnectingPeripheral = nil
        writeCharacteristic = nil
        callbackOnReceive = nil
        forceDisconnect = false

        UIApplication.shared.isIdleTimerDisabled = false
        notificationCenter.post(name: Notification.Name.Serial.didFailToConnect, object: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if state != .poweredOn {
            if isConnected {
                log("Disconnected")
                MessageView.show("Disconnected")
                notificationCenter.post(name: Notification.Name.Serial.didDisconnect, object: nil)
                UIApplication.shared.isIdleTimerDisabled = false
            } else if isConnecting || isReconnecting {
                log("Disconnected")
                notificationCenter.post(name: Notification.Name.Serial.didFailToConnect, object: nil)
                UIApplication.shared.isIdleTimerDisabled = false
            }
            
            pendingPeripheral = nil
            connectedPeripheral = nil
            writeCharacteristic = nil
            discoveredPeripherals = []
            callbackOnReceive = nil
            msp.didDisconnect()
        }
        
        notificationCenter.post(name: Notification.Name.Serial.didUpdateState, object: nil)
    }


    // MARK: - CBPeripheralDelegate functions
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // discover FFE1 characteristics for all services
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // check whether the characteristic we're looking for (0xFFE1) is present
        for characteristic in service.characteristics! {
            if characteristic.uuid == CBUUID(string: "FFE1") {
                // subscribe to this value (so we'll get notified when there is serial data for us..)
                peripheral.setNotifyValue(true, for: characteristic)
                
                // now we can send data to the peripheral
                pendingPeripheral = nil
                connectedPeripheral = peripheral
                writeCharacteristic = characteristic
                var verified = false
                
                // Before we're ready we have to check (If we don't know this peripheral yet)
                // 1) Whether we have to write with or without response
                // 2) Whether it actually repsonds
                // 3) Whether CLI mode is activated
                // To do this, we'll
                // 1) Send an MSP command without response
                // 2) (If unresponsive) Send an MSP command with response
                // 3) (If still unresponsive) Send 'asdf\r' without response
                //    3b) If responsive send 'exit\r' to exit CLI mode
                // 4) (If still unresponsive) Send 'asdf\r' with response
                //    4b) If responsive send 'exit\r' to exit CLI mode
                // 5) (If still unresponsive) Abort connection and send notification
                //
                // If we do know this peripheral, we will only check if CLI mode is activated
                //
                
                func ready() {
                    verified = true
                    
                    // we already got MSP_API_VERSION, so let's check the min and max versions
                    if dataStorage.apiVersion >= apiMaxVersion || dataStorage.apiVersion < apiMinVersion {
                        log(.Warn, "FC API version not compatible. API: \(dataStorage.apiVersion) MSP: \(dataStorage.mspVersion)")
                        
                        let alert = UIAlertController(title: "Firmware not compatible", message: "The API version is either too old or too new.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Dismiss", style: .default) { _ in cancel() })
                        presentViewController(alert)
                        
                        return
                    }
                    
                    if let device = BluetoothDevice.deviceWithUUID(peripheral.identifier) {
                        // check if name is still the same
                        if peripheral.name ?? "Unidentified" != device.name {
                            device.name = peripheral.name ?? "Unidentified"
                            BluetoothDevice.saveDevices()
                        }
                    } else {
                        // add to our list of recognized devices
                        BluetoothDevice.devices.append(BluetoothDevice(name: peripheral.name ?? "Unidentified",
                                                                       UUID: peripheral.identifier,
                                                                autoConnect: true,
                                                          writeWithResponse: writeType == .withResponse))
                        BluetoothDevice.saveDevices()

                    }
                    
                    // send first MSP commands for the board info stuff
                    msp.sendMSP([MSP_FC_VARIANT, MSP_FC_VERSION, MSP_BOARD_INFO, MSP_BUILD_INFO]) {
                        log("Connected")
                        log("Eaze v\(appVersion.stringValue), iOS \(UIDevice.current.systemVersion), Platform \(UIDevice.platform)")
                        log("FC ID \(dataStorage.flightControllerIdentifier), v\(dataStorage.flightControllerVersion.stringValue), Build \(dataStorage.buildInfo)")
                        log("FC API v\(dataStorage.apiVersion.stringValue), MSP v\(dataStorage.mspVersion)")
                        log("Board ID \(dataStorage.boardIdentifier) v\(dataStorage.boardVersion)")
                        
                        // these only have to be sent once (boxnames is for the mode titles)
                        msp.sendMSP([MSP_BOXNAMES, MSP_BOXIDS, MSP_STATUS])
                        
                        // the user will be happy to know
                        MessageView.show("Connected")
                        
                        // proceed to tell the rest of the app about recent events
                        notificationCenter.post(name: Notification.Name.Serial.didConnect, object: nil)
                        
                        // disable sleep
                        UIApplication.shared.isIdleTimerDisabled = true
                    }
                }
                
                func fail() {
                    guard !verified && isConnected else { return }
                    callbackOnReceive = nil // prevent exitCLI from being called next time we connect
                    log("Module not responding")
                    
                    let alert = UIAlertController(title: "Module not responding", message: "Connect anyway?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in cancel() })
                    alert.addAction(UIAlertAction(title: "Connect", style: .default) { _ in
                        guard self.isConnected else { return }
                        
                        log("Connecting anyway..")
                        log("Eaze v\(appVersion.stringValue), iOS \(UIDevice.current.systemVersion), Platform \(UIDevice.platform)")
                        
                        MessageView.show("Connected")
                        notificationCenter.post(name: Notification.Name.Serial.didConnect, object: nil)
                        
                        // disable sleep
                        UIApplication.shared.isIdleTimerDisabled = true
                    })

                    presentViewController(alert)
                }
                
                func cancel() {
                    disconnect()
                    notificationCenter.post(name: Notification.Name.Serial.didFailToConnect, object: nil)
                }
                
                func exitCLI(_ data: Data) {
                    // if the RX pin on the HM10 is not connected to anything, it sends 0x00 bytes randomly
                    // (triggered by static probably). We only want to exit the cli if we get a valid string
                    // back (something like "# Unknown command, try 'help'"). Hence the following statement.
                    guard data.getBytes() != [UInt8(0)] else { return }
                    
                    verified = true // prevent 'fail' from being called
                    log("CLI appears to be active")
                    
                    let alert = UIAlertController(title: "CLI is active", message: "Exit CLI mode? This will reboot the flightcontroller and discard unsaved changes", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel connecting", style: .cancel) { _ in
                        cancel()
                    })
                    
                    alert.addAction(UIAlertAction(title: "Don't exit CLI", style: .default) { _ in
                        guard self.isConnected else { return }

                        log("Connecting anyway..")
                        log("Eaze v\(appVersion.stringValue), iOS \(UIDevice.current.systemVersion), Platform \(UIDevice.platform)")
                        
                        cliActive = true
                        MessageView.show("Connected")
                        notificationCenter.post(name: Notification.Name.Serial.didConnect, object: nil)
                        
                        // disable sleep
                        UIApplication.shared.isIdleTimerDisabled = true
                    })
                    
                    alert.addAction(UIAlertAction(title: "Exit CLI", style: .destructive) { _ in
                        guard self.isConnected else { return }

                        log("Exiting CLI")
                        self.sendStringToDevice("exit\r")
                        MessageView.showProgressHUD("Waiting for FC to exit CLI mode")
                        delay(5.0) { // wait for device to reboot
                            msp.reset() // clear all the cli stuff it received
                            msp.sendMSP(MSP_API_VERSION, callback: ready) // proceed as if nothing happened
                            MessageView.hideProgressHUD()
                        }
                    })
                    
                    presentViewController(alert)
                }
                
                func firstTry() {
                    callbackOnReceive = nil
                    writeType = .withoutResponse
                    msp.sendMSP(MSP_API_VERSION, callback: ready)
                    delay(2.0, callback: secondTry)
                }
                
                func secondTry() {
                    guard !verified && isConnected else { return }
                    writeType = .withResponse
                    msp.sendMSP(MSP_API_VERSION) // callback is still in place
                    delay(2.0, callback: thirdTry)
                }
                
                func thirdTry() {
                    guard !verified && isConnected else { return }
                    msp.callbacks = [] // clear callback so it doesn't get called later
                    writeType = .withoutResponse
                    callbackOnReceive = exitCLI
                    sendStringToDevice("asdf\r")
                    delay(2.0, callback: fourthTry)
                }
                
                func fourthTry() {
                    guard !verified && isConnected else { return }
                    writeType = .withResponse
                    sendStringToDevice("asdf\r")
                    delay(2.0, callback: fail)
                }
                
                func smartFirstTry() {
                    writeType = BluetoothDevice.deviceWithUUID(peripheral.identifier)!.writeWithResponse ? .withResponse : .withoutResponse
                    msp.sendMSP(MSP_API_VERSION, callback: ready)
                    delay(2.0, callback: smartSecondTry)
                }
                
                func smartSecondTry() {
                    guard !verified && isConnected else { return }
                    msp.callbacks = [] // clear callback so it doesn't get called later
                    callbackOnReceive = exitCLI
                    sendStringToDevice("asdf\r")
                    delay(2.0, callback: firstTry) // go through the other possibilities as well
                }
                
                if BluetoothDevice.deviceWithUUID(peripheral.identifier) != nil {
                    smartFirstTry()
                } else {
                    firstTry()
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if callbackOnReceive != nil {
            callbackOnReceive?(characteristic.value!)
            callbackOnReceive = nil
        }
        
        delegate?.serialPortReceivedData(characteristic.value!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        rssiCallback?(RSSI)
    }
    
    
    // MARK: - Misc helper functions
    fileprivate func presentViewController(_ viewController: UIViewController) {
        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
        while let newRoot = rootViewController?.presentedViewController { rootViewController = newRoot }
        rootViewController?.present(viewController, animated: true, completion: nil)
    }
}
