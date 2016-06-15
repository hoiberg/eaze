//
//  ScanViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 18-04-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

class ConnectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter.addObserver( tableView,
                              selector: #selector(UITableView.reloadData),
                                  name: BluetoothSerialDidDiscoverNewPeripheralNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(ConnectViewController.serialDidConnect),
                                  name: BluetoothSerialDidConnectNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(ConnectViewController.serialWillAutoConnect),
                                  name: BluetoothSerialWillAutoConnectNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(ConnectViewController.serialDidFailToConnect),
                                  name: BluetoothSerialDidFailToConnectNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(ConnectViewController.serialStateChanged),
                                  name: BluetoothSerialDidUpdateStateNotification,
                                object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    
    // MARK: - Bluetooth Serial events
    
    func serialDidConnect() {
        log("C serial did connect")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func serialWillAutoConnect() {
        log("C serial will auto connect")
        tableView.reloadData()
        tableView.allowsSelection = false
    }
    
    func serialDidFailToConnect() {
        log("C serial did fail to connect")
        tableView.reloadData()
        tableView.allowsSelection = true
    }
    
    func serialStateChanged() {
        log("C serial state changed")
        if bluetoothSerial.state != .PoweredOn {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
    // MARK: - UITableView
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetoothSerial.discoveredPeripherals.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PeripheralCell")!,
            label = cell.viewWithTag(2) as! UILabel,
            peripheral = bluetoothSerial.discoveredPeripherals[indexPath.row].peripheral
        label.text = peripheral.name ?? "Unidentified"
        
        if peripheral == bluetoothSerial.pendingPeripheral {
            let activityIndicator = cell.viewWithTag(1) as! UIActivityIndicatorView
            activityIndicator.startAnimating()
        }
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        tableView.allowsSelection = false
        
        bluetoothSerial.stopScan()
        
        let peripheral = bluetoothSerial.discoveredPeripherals[indexPath.row].peripheral
        bluetoothSerial.connectToPeripheral(peripheral)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)!,
            activityIndicator = cell.viewWithTag(1) as! UIActivityIndicatorView
        activityIndicator.startAnimating()
    }
    

    // MARK: - IBActions
    
    @IBAction func cancel(sender: UIButton) {
        bluetoothSerial.stopScan()
        bluetoothSerial.disconnect()
        dismissViewControllerAnimated(true, completion: nil )
    }
}