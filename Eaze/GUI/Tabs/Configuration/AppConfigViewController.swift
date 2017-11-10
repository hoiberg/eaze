//
//  AppConfigViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 14-03-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

class AppConfigViewController: GroupedTableViewController {
    
    // MARK: - Variables
    
    fileprivate var autoConnectNew, autoConnectOld: UISwitch?
    fileprivate var devices: [BluetoothDevice] { return BluetoothDevice.devices }
    

    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = self.editButtonItem
    }

    
    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return devices.count > 0 ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count > 0 && section == 0 ? devices.count : 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if devices.count > 0 && indexPath.section == 0 {
            // device cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothDeviceCell", for: indexPath)
            cell.textLabel?.text = devices[indexPath.row].name
            return cell
        } else {
            if indexPath.row == 0 {
                // auto connect new modules cell
                return tableView.dequeueReusableCell(withIdentifier: "AutoConnectNewCell", for: indexPath)
            } else {
                // auto connect old modules cell
                return tableView.dequeueReusableCell(withIdentifier: "AutoConnectOldCell", for: indexPath)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return devices.count > 0 && section == 0 ? "Bluetooth modules" : "Auto Connect"
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        if let slider = cell.viewWithTag(1) {
            // auto connect new modules
            (slider as! UISwitch).isOn = userDefaults.bool(forKey: DefaultsAutoConnectNewKey)
        } else if let slider = cell.viewWithTag(2) {
            // auto connect old modules
            (slider as! UISwitch).isOn = userDefaults.bool(forKey: DefaultsAutoConnectOldKey)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return devices.count > 0 && indexPath.section == 0 ? true : false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            BluetoothDevice.devices.remove(at: indexPath.row)
            BluetoothDevice.saveDevices()
            if devices.count == 0 {
                tableView.deleteSections(IndexSet(integer: 0), with: .fade)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }

    
    // MARK: - IBActions
    
    @IBAction func autoConnectNewChanged(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: DefaultsAutoConnectNewKey)
        userDefaults.synchronize()
    }
    
    @IBAction func autoConnectOldChanged(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: DefaultsAutoConnectOldKey)
        userDefaults.synchronize()
    }
}
