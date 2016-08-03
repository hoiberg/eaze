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
    
    private var autoConnectNew, autoConnectOld: UISwitch?
    private var devices: [BluetoothDevice] { return BluetoothDevice.devices }

    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    
    // MARK: - TableView

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return devices.count > 0 ? 2 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count > 0 && section == 0 ? devices.count : 2
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if devices.count > 0 && indexPath.section == 0 {
            // device cell
            let cell = tableView.dequeueReusableCellWithIdentifier("BluetoothDeviceCell", forIndexPath: indexPath)
            cell.textLabel?.text = devices[indexPath.row].name
            return cell
        } else {
            if indexPath.row == 0 {
                // auto connect new modules cell
                return tableView.dequeueReusableCellWithIdentifier("AutoConnectNewCell", forIndexPath: indexPath)
            } else {
                // auto connect old modules cell
                return tableView.dequeueReusableCellWithIdentifier("AutoConnectOldCell", forIndexPath: indexPath)
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return devices.count > 0 && section == 0 ? "Bluetooth modules" : "Auto Connect"
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
        if let slider = cell.viewWithTag(1) {
            // auto connect new modules
            (slider as! UISwitch).on = userDefaults.boolForKey(DefaultsAutoConnectNewKey)
        } else if let slider = cell.viewWithTag(2) {
            // auto connect old modules
            (slider as! UISwitch).on = userDefaults.boolForKey(DefaultsAutoConnectOldKey)
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return devices.count > 0 && indexPath.section == 0 ? true : false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            BluetoothDevice.devices.removeAtIndex(indexPath.row)
            BluetoothDevice.saveDevices()
            if devices.count == 0 {
                tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
            } else {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        }
    }

    
    // MARK: - IBActions
    
    @IBAction func autoConnectNewChanged(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: DefaultsAutoConnectNewKey)
        userDefaults.synchronize()
    }
    
    @IBAction func autoConnectOldChanged(sender: UISwitch) {
        userDefaults.setBool(sender.on, forKey: DefaultsAutoConnectOldKey)
        userDefaults.synchronize()
    }
}