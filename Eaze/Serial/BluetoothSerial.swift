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
//  1) In viewDidLoad
//      a) subscribe to the MSP codes you're going to send (at least those you need the reaction of..)
//      b) if already connected, send MSP codes and enable buttons etc
//      c) if not connected, disable buttons etc
//  2) Subscribe to BluetoothSerialDidConnectNotification (*)
//      in whose selector you send MSP codes and enable buttons etc
//  3) Subscribe to BluetoothSerialDidDisconnectNotification
//      in whose selector you disable buttons etc
//  4) Implement the MSPSubscriber protocol (if neccesary) and put a switch statement in there
//      in which you update the UI and other stuff according to the code (data) received
//
//  If the viewController sends continous msp data requests, it needs to start the timer in
//  viewWillAppear, AppDidBecomeActive and serialDidOpen (the latter two only if isBeingShown)
//  It then stops the timer in viewWillDisappear, AppWillResignActive and serialDidClose (again, the latter two only if isBeingShown).
//
//  Note: yes, you can use sendMSP(code, callback), but its purpose is for when timing is important (calibration, reset etc), not UI updates.
//  *: In case the VC is still in memory while connecting - the actual connecting does only happen on the Dashboard tab.

//TODO: Alleen views msp senden in viewwillappear??

import UIKit
import CoreBluetooth

let BluetoothSerialWillAutoConnectNotification = "BluetoothSerialWillConnect"
let BluetoothSerialDidConnectNotification = "BluetoothSerialDidConnect"
let BluetoothSerialDidFailToConnectNotification = "BluetoothSerialDidFailToConnect"
let BluetoothSerialDidDisconnectNotification = "BluetoothSerialDidDisconnect"
let BluetoothSerialDidDiscoverNewPeripheralNotification = "BluetoothSerialDidDiscoverNewPeripheral"
let BluetoothSerialDidUpdateStateNotification = "BluetoothDidUpdateState"
let BluetoothSerialDidStopScanningNotification = "BluetoothDidStopScanning"

let SerialOpenedNotification = BluetoothSerialDidConnectNotification
let SerialClosedNotification = BluetoothSerialDidDisconnectNotification

protocol BluetoothSerialDelegate {
    func serialPortReceivedData(data: NSData)
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
    private weak var writeCharacteristic: CBCharacteristic?
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var discoveredPeripherals: [(peripheral: CBPeripheral!, RSSI: Float)] = []
    
    /// The state of the bluetooth manager (use this to determine whether it is on or off or disabled etc)
    var state: CBCentralManagerState {
        return centralManager.state
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
    var writeType = CBCharacteristicWriteType.WithResponse
    
    /// Function called the next time some data is received (to be used for testing the connection)
    private var callbackOnReceive: (NSData -> Void)?
    
    /// Function called when RSSI is read
    private var rssiCallback: (NSNumber -> Void)?
    
    /// Whether to expect a disconnection
    private var forceDisconnect = false
    
    
    // MARK: - Functions
    
    /// Initializor
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Start scanning for peripherals
    func startScan() {
        guard centralManager.state == .PoweredOn else { return }
        log("Start scanning")
        
        discoveredPeripherals = []
        
        // search for devices with correct service UUID, and allow duplicates for RSSI update (but only if it is needed for auto connecting new peripherals)
        centralManager.scanForPeripheralsWithServices( [CBUUID(string: "FFE0")],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey: userDefaults.boolForKey(DefaultsAutoConnectNewKey)])
        
        // maybe the peripheral is still connected
        for peripheral in centralManager.retrieveConnectedPeripheralsWithServices([CBUUID(string: "FFE0")]) {
            evaluatePeripheral(peripheral, RSSI: nil)
        }
    }
    
    /// Try to connect to the given peripheral
    func connectToPeripheral(peripheral: CBPeripheral) {
        guard centralManager.state == .PoweredOn else { return }
        log("Connecting to peripheral \(peripheral.name ?? "Unknown")")
        
        pendingPeripheral = peripheral
        centralManager.connectPeripheral(peripheral, options: nil)
        delay(10) {
            // timeout
            guard self.isConnecting else { return }
            log("Connection timeout")
            self.disconnect()
            notificationCenter.postNotificationName(BluetoothSerialDidFailToConnectNotification, object: nil)
        }
    }
    
    /// Stop scanning for new peripherals
    func stopScan() {
        guard centralManager.state == .PoweredOn else { return }
        log("Stopped scanning")
        
        centralManager.stopScan()
        notificationCenter.postNotificationName(BluetoothSerialDidStopScanningNotification, object: nil)
    }
    
    /// Disconnect from the connected peripheral, the pending preipheral, or the reconnecting peripheral
    func disconnect() {
        guard centralManager.state == .PoweredOn else { return }
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
    func sendBytesToDevice(bytes: [UInt8]) {
        guard isConnected else { return }
                
        let data = NSData(bytes: bytes, length: bytes.count)
        connectedPeripheral!.writeValue(data, forCharacteristic: writeCharacteristic!, type: writeType)
    }
    
    /// Send a string to the HM10 (only supports 8-bit UTF8 encoding)
    func sendStringToDevice(string: String) {
        guard isConnected else { return }
        
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            connectedPeripheral!.writeValue(data, forCharacteristic: writeCharacteristic!, type: writeType)
        }
    }
    
    /// Send a NSData object to the HM10
    func sendDataToDevice(data: NSData) {
        guard isConnected else { return }
        
        connectedPeripheral!.writeValue(data, forCharacteristic: writeCharacteristic!, type: writeType)
    }
    
    /// Read RSSI
    func readRSSI(callback: NSNumber -> Void) {
        guard isConnected else { return }
        rssiCallback = callback
        connectedPeripheral!.readRSSI()
    }
    
    private func evaluatePeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {
        var isKnown = false,
            autoConnect = false
        
        // check if we already have met this device before
        if BluetoothDevice.deviceWithUUID(peripheral.identifier) != nil {
            isKnown = true
        }
        
        // we do this before checking for duplicates for RSSI updates
        if userDefaults.boolForKey(DefaultsAutoConnectNewKey) && RSSI?.integerValue > -70 && !isKnown {
            stopScan()
            connectToPeripheral(peripheral)
            notificationCenter.postNotificationName(BluetoothSerialWillAutoConnectNotification, object: nil)
            autoConnect = true
        }
        
        // stop if it is a duplicate
        for exisiting in discoveredPeripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }
        
        // auto connect if we already know this device
        if userDefaults.boolForKey(DefaultsAutoConnectOldKey) && isKnown {
            stopScan()
            connectToPeripheral(peripheral)
            notificationCenter.postNotificationName(BluetoothSerialWillAutoConnectNotification, object: nil)
            autoConnect = true
        }
        
        // add to the array, next sort & reload & send notification
        discoveredPeripherals.append((peripheral: peripheral, RSSI: RSSI?.floatValue ?? -100.0))
        discoveredPeripherals.sortInPlace { $0.RSSI < $1.RSSI }
        
        notificationCenter.postNotificationName(BluetoothSerialDidDiscoverNewPeripheralNotification, object: nil, userInfo: ["WillAutoConnect": autoConnect])
    }
    
    
    // MARK: - CBCentralManagerDelegate functions
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        evaluatePeripheral(peripheral, RSSI: RSSI)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
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
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        let wasConnected = isConnected
        
        pendingPeripheral = nil
        connectedPeripheral = nil
        writeCharacteristic = nil
        callbackOnReceive = nil
        msp.didDisconnect() // reset & clear callbacks
        
        log("Disconnected")
        MessageView.show("Disconnected")
        notificationCenter.postNotificationName(BluetoothSerialDidDisconnectNotification, object: nil)
        
        if forceDisconnect || !wasConnected {
            // re-enable sleep
            UIApplication.sharedApplication().idleTimerDisabled = false
            forceDisconnect = false
        } else {
            // reconnect
            reconnectingPeripheral = peripheral
            centralManager.connectPeripheral(peripheral, options: nil)
            
            // switch back to homeviewcontroller
            let tab = UIApplication.sharedApplication().windows.first?.rootViewController as! UITabBarController
            tab.selectedIndex = 0
            
            // now that the homeviewcontroller is visible, send the notification
            notificationCenter.postNotificationName(BluetoothSerialWillAutoConnectNotification, object: nil)
        }
        
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        log("Failed to connect")
        
        pendingPeripheral = nil
        reconnectingPeripheral = nil
        writeCharacteristic = nil
        callbackOnReceive = nil
        forceDisconnect = false

        UIApplication.sharedApplication().idleTimerDisabled = false
        notificationCenter.postNotificationName(BluetoothSerialDidFailToConnectNotification, object: nil)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if state != .PoweredOn {
            if isConnected {
                log("Disconnected")
                MessageView.show("Disconnected")
                notificationCenter.postNotificationName(BluetoothSerialDidDisconnectNotification, object: nil)
                UIApplication.sharedApplication().idleTimerDisabled = false
            } else if isConnecting || isReconnecting {
                log("Disconnected")
                notificationCenter.postNotificationName(BluetoothSerialDidFailToConnectNotification, object: nil)
                UIApplication.sharedApplication().idleTimerDisabled = false
            }
            
            pendingPeripheral = nil
            connectedPeripheral = nil
            writeCharacteristic = nil
            discoveredPeripherals = []
            callbackOnReceive = nil
            msp.didDisconnect()
        }
        
        notificationCenter.postNotificationName(BluetoothSerialDidUpdateStateNotification, object: nil)
    }


    // MARK: - CBPeripheralDelegate functions
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        // discover FFE1 characteristics for all services
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        // check whether the characteristic we're looking for (0xFFE1) is present
        for characteristic in service.characteristics! {
            if characteristic.UUID == CBUUID(string: "FFE1") {
                // subscribe to this value (so we'll get notified when there is serial data for us..)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                
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
                        
                        let alert = UIAlertController(title: "Firmware not compatible", message: "The API version is either too old or too new.", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default) { _ in cancel() })
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
                                                          writeWithResponse: writeType == .WithResponse))
                        BluetoothDevice.saveDevices()

                    }
                    
                    // send first MSP commands for the board info stuff
                    msp.sendMSP([MSP_FC_VARIANT, MSP_FC_VERSION, MSP_BOARD_INFO, MSP_BUILD_INFO]) {
                        log("Connected")
                        log("Eaze v\(appVersion.stringValue), iOS \(UIDevice.currentDevice().systemVersion), Platform \(UIDevice.platform)")
                        log("FC ID \(dataStorage.flightControllerIdentifier), v\(dataStorage.flightControllerVersion.stringValue), Build \(dataStorage.buildInfo)")
                        log("FC API v\(dataStorage.apiVersion.stringValue), MSP v\(dataStorage.mspVersion)")
                        log("Board ID \(dataStorage.boardIdentifier) v\(dataStorage.boardVersion)")
                        
                        // these only have to be sent once (boxnames is for the mode titles)
                        msp.sendMSP([MSP_BOXNAMES, MSP_BOXIDS, MSP_STATUS])
                        
                        // the user will be happy to know
                        MessageView.show("Connected")
                        
                        // proceed to tell the rest of the app about recent events
                        notificationCenter.postNotificationName(BluetoothSerialDidConnectNotification, object: nil)
                        
                        // disable sleep
                        UIApplication.sharedApplication().idleTimerDisabled = true
                    }
                }
                
                func fail() {
                    guard !verified && isConnected else { return }
                    callbackOnReceive = nil // prevent exitCLI from being called next time we connect
                    log("Module not responding")
                    
                    let alert = UIAlertController(title: "Module not responding", message: "Connect anyway?", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { _ in cancel() })
                    alert.addAction(UIAlertAction(title: "Connect", style: .Default) { _ in
                        guard self.isConnected else { return }
                        
                        log("Connecting anyway..")
                        log("Eaze v\(appVersion.stringValue), iOS \(UIDevice.currentDevice().systemVersion), Platform \(UIDevice.platform)")
                        
                        MessageView.show("Connected")
                        notificationCenter.postNotificationName(BluetoothSerialDidConnectNotification, object: nil)
                        
                        // disable sleep
                        UIApplication.sharedApplication().idleTimerDisabled = true
                    })

                    presentViewController(alert)
                }
                
                func cancel() {
                    disconnect()
                    notificationCenter.postNotificationName(BluetoothSerialDidFailToConnectNotification, object: nil)
                }
                
                func exitCLI(data: NSData) {
                    // if the RX pin on the HM10 is not connected to anything, it sends 0x00 bytes randomly
                    // (triggered by static probably). We only want to exit the cli if we get a valid string
                    // back (something like "# Unknown command, try 'help'"). Hence the following statement.
                    guard data.getBytes() != [UInt8(0)] else { return }
                    
                    verified = true // prevent 'fail' from being called
                    log("CLI appears to be active")
                    
                    let alert = UIAlertController(title: "CLI is active", message: "Exit CLI mode? This will reboot the flightcontroller and discard unsaved changes", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Cancel connecting", style: .Cancel) { _ in
                        cancel()
                    })
                    
                    alert.addAction(UIAlertAction(title: "Don't exit CLI", style: .Default) { _ in
                        guard self.isConnected else { return }

                        log("Connecting anyway..")
                        log("Eaze v\(appVersion.stringValue), iOS \(UIDevice.currentDevice().systemVersion), Platform \(UIDevice.platform)")
                        
                        cliActive = true
                        MessageView.show("Connected")
                        notificationCenter.postNotificationName(BluetoothSerialDidConnectNotification, object: nil)
                        
                        // disable sleep
                        UIApplication.sharedApplication().idleTimerDisabled = true
                    })
                    
                    alert.addAction(UIAlertAction(title: "Exit CLI", style: .Destructive) { _ in
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
                    writeType = .WithoutResponse
                    msp.sendMSP(MSP_API_VERSION, callback: ready)
                    delay(1.0, callback: secondTry)
                }
                
                func secondTry() {
                    guard !verified && isConnected else { return }
                    writeType = .WithResponse
                    msp.sendMSP(MSP_API_VERSION) // callback is still in place
                    delay(1.0, callback: thirdTry)
                }
                
                func thirdTry() {
                    guard !verified && isConnected else { return }
                    msp.callbacks = [] // clear callback so it doesn't get called later
                    writeType = .WithoutResponse
                    callbackOnReceive = exitCLI
                    sendStringToDevice("asdf\r")
                    delay(1.0, callback: fourthTry)
                }
                
                func fourthTry() {
                    guard !verified && isConnected else { return }
                    writeType = .WithResponse
                    sendStringToDevice("asdf\r")
                    delay(1.0, callback: fail)
                }
                
                func smartFirstTry() {
                    writeType = BluetoothDevice.deviceWithUUID(peripheral.identifier)!.writeWithResponse ? .WithResponse : .WithoutResponse
                    msp.sendMSP(MSP_API_VERSION, callback: ready)
                    delay(1.0, callback: smartSecondTry)
                }
                
                func smartSecondTry() {
                    guard !verified && isConnected else { return }
                    msp.callbacks = [] // clear callback so it doesn't get called later
                    callbackOnReceive = exitCLI
                    sendStringToDevice("asdf\r")
                    delay(1.0, callback: fail)
                }
                
                if BluetoothDevice.deviceWithUUID(peripheral.identifier) != nil {
                    smartFirstTry()
                } else {
                    firstTry()
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if callbackOnReceive != nil {
            callbackOnReceive?(characteristic.value!)
            callbackOnReceive = nil
        }
        
        delegate?.serialPortReceivedData(characteristic.value!)
    }
    
    func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        rssiCallback?(RSSI)
    }
    
    
    // MARK: - Misc helper functions
    private func presentViewController(viewController: UIViewController) {
        var rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        while let newRoot = rootViewController?.presentedViewController { rootViewController = newRoot }
        rootViewController?.presentViewController(viewController, animated: true, completion: nil)
    }
}