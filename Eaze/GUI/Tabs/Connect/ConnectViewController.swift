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
                                  name: Notification.Name.Serial.didDiscoverNewPeripheral,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(serialDidConnect),
                                  name: Notification.Name.Serial.didConnect,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(serialWillAutoConnect),
                                  name: Notification.Name.Serial.willAutoConnect,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(serialDidFailToConnect),
                                  name: Notification.Name.Serial.didFailToConnect,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(serialStateChanged),
                                  name: Notification.Name.Serial.didUpdateState,
                                object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    
    // MARK: - Bluetooth Serial events
    
    @objc func serialDidConnect() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func serialWillAutoConnect() {
        tableView.reloadData()
        tableView.allowsSelection = false
    }
    
    @objc func serialDidFailToConnect() {
        tableView.reloadData()
        tableView.allowsSelection = true
    }
    
    @objc func serialStateChanged() {
        if bluetoothSerial.state != .poweredOn {
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    // MARK: - UITableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetoothSerial.discoveredPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralCell")!,
            label = cell.viewWithTag(2) as! UILabel,
            peripheral = bluetoothSerial.discoveredPeripherals[indexPath.row].peripheral
        label.text = peripheral?.name ?? "Unidentified"
        
        if peripheral == bluetoothSerial.pendingPeripheral {
            let activityIndicator = cell.viewWithTag(1) as! UIActivityIndicatorView
            activityIndicator.startAnimating()
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.allowsSelection = false
        
        bluetoothSerial.stopScan()
        
        let peripheral = bluetoothSerial.discoveredPeripherals[indexPath.row].peripheral
        bluetoothSerial.connectToPeripheral(peripheral!)
        
        let cell = tableView.cellForRow(at: indexPath)!,
            activityIndicator = cell.viewWithTag(1) as! UIActivityIndicatorView
        activityIndicator.startAnimating()
    }
    

    // MARK: - IBActions
    
    @IBAction func cancel(_ sender: UIButton) {
        bluetoothSerial.stopScan()
        bluetoothSerial.disconnect()
        dismiss(animated: true, completion: nil )
    }
}
