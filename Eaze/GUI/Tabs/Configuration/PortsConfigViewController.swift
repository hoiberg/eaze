//
//  PortsConfigViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 09-12-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

class PortsConfigViewController: GroupedTableViewController, MSPUpdateSubscriber, SelectionTableViewControllerDelegate {

    // MARK: - IBOutlets
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    // MARK: - Variables
    
    private let mspCodes = [MSP_CF_SERIAL_CONFIG]
    private var ports: [SerialPortConfig] = [] // Working copy of dataStorage's serialPorts
    

    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addSubscriber(self, forCodes: mspCodes)
        if bluetoothSerial.isConnected {
            serialOpened()
        } else {
            serialClosed()
        }
        
        notificationCenter.addObserver(self, selector: #selector(PortsConfigViewController.serialOpened), name: SerialOpenedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PortsConfigViewController.serialClosed), name: SerialClosedNotification, object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    
    // MARK: Data request / update
    
    func sendDataRequest() {
        msp.sendMSP(mspCodes)
    }
    
    func mspUpdated(code: Int) {
        switch code {
        case MSP_CF_SERIAL_CONFIG:
            ports = dataStorage.serialPorts
            tableView.reloadData()
            
        default:
            log(.Warn, "PortsConfigViewController received MSP code not subscribed to: \(code)")
        }
    }
    
    
    // MARK: - Serial events
    
    func serialOpened() {
        if dataStorage.apiVersion >= "1.6.0" {
            sendDataRequest()
            saveButton.enabled = true
        } else {
            ports = []
            saveButton.enabled = false
            tableView.reloadData()
        }
    }
    
    func serialClosed() {
        saveButton.enabled = false
    }
    
    
    // MARK: SelectionTableViewControllerDelegate
    
    func selectionTableWithTag(tag: Int, didSelectItem item: Int) {
        let port = ports[Int(floor(Float(tag) / 7.0))]
        let row = tag % 7
        
        switch row {
        case 0: // msp
            if item == 0 { // disabled
                port.functions.removeObject(.MSP)
            } else { // enabled, add if it doesn't exist already
                port.functions.appendIfNonexistent(.MSP)
                let options: [Baudrate] = [.B9600, .B19200, .B38400, .B57600, .B115200]
                port.MSP_baudrate = options[item - 1]
            }
            
        case 1: // blackbox
            if item == 0 { // disabled
                port.functions.removeObject(.BLACKBOX)
            } else { // enabled, add if it doesn't exist already
                port.functions.appendIfNonexistent(.BLACKBOX)
                let options: [Baudrate] = [.B19200, .B38400, .B57600, .B115200, .B230400, .B250000]
                port.BLACKBOX_baudrate = options[item - 1]
            }
            
        case 2: // telemetry type
            // first remove all, then add the new one
            port.functions.removeObjects([.TELEMETRY_FRSKY, .TELEMETRY_HOTT, .TELEMETRY_MSP, .TELEMETRY_SMARTPORT])
            if item > 0 {
                let options: [SerialPortFunction] = [.TELEMETRY_FRSKY, .TELEMETRY_HOTT, .TELEMETRY_MSP, .TELEMETRY_SMARTPORT]
                port.functions.append(options[item - 1])
            }
            
        case 3: // telemetry baudrate
            let options: [Baudrate] = [.Auto, .B9600, .B19200, .B38400, .B57600, .B115200]
            port.TELEMETRY_baudrate = options[item]
            
        case 4: // Serial RX
            if item == 0 {
                port.functions.removeObject(.RX_SERIAL)
            } else {
                port.functions.appendIfNonexistent(.RX_SERIAL)
            }
            
        case 5: // GPS
            if item == 0 { // disabled
                port.functions.removeObject(.GPS)
            } else { // enabled, add if it doesn't exist already
                port.functions.appendIfNonexistent(.GPS)
                let options: [Baudrate] = [.B9600, .B19200, .B38400, .B57600, .B115200]
                port.GPS_baudrate = options[item - 1]
            }
            
        default:
            log(.Warn, "PortsConfigurationViewController: item value too high (\(row))")
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1 + dataStorage.serialPorts.count // one for the message cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 7
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // return the right cell
        if indexPath.section == 0 {
            // message cell
            let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell")!
            if dataStorage.apiVersion == "0.0.0" || dataStorage.apiVersion >= "1.6.0" {
                (cell.viewWithTag(1) as! UILabel).text = UIDevice.isPhone ?
                    "Not all combinations are valid. When the flight controller detects this the serial port configuration will be reset. Do not disable MSP on the first serial port unless unless you know what you are doing!" :
                    "Note: Not all combinations are valid. When the flight controller detects this the serial port configuration will be reset.\nNote: Do not disable MSP on the first serial port unless unless you know what you are doing!"
            } else {
                (cell.viewWithTag(1) as! UILabel).text = "Serial port configuration requires Cleanflight 1.6.0 or higher, you are running \(dataStorage.apiVersion.stringValue)"
            }
            return cell
        } else {
            if dataStorage.serialPorts.count < indexPath.section {
                log(.Error, "Too many sections (\(indexPath.section)) in PortConfigViewController! This should not be possible.")
                return tableView.dequeueReusableCellWithIdentifier("TitleCell")!
            }
            
            let port = dataStorage.serialPorts[indexPath.section - 1]
            switch indexPath.row {
            case 0: // title
                let cell = tableView.dequeueReusableCellWithIdentifier("TitleCell")!
                (cell.viewWithTag(1) as! UILabel).text = port.name
                return cell
                
            case 1: // msp
                let cell = tableView.dequeueReusableCellWithIdentifier("MSPCell")!
                cell.detailTextLabel?.text = port.functions.contains(.MSP) ? port.MSP_baudrate.name : "Disabled"
                return cell
                
            case 2: // blackbox
                let cell = tableView.dequeueReusableCellWithIdentifier("BlackboxCell")!
                cell.detailTextLabel?.text = port.functions.contains(SerialPortFunction.BLACKBOX) ? port.BLACKBOX_baudrate.name : "Disabled"
                return cell

            case 3: // telemetry type
                let cell = tableView.dequeueReusableCellWithIdentifier("TelemetryCell")!
                if port.functions.contains(SerialPortFunction.TELEMETRY_FRSKY) {
                    cell.detailTextLabel?.text = "FrSky"
                } else if port.functions.contains(SerialPortFunction.TELEMETRY_HOTT) {
                    cell.detailTextLabel?.text = "Graupner HOTT"
                } else if port.functions.contains(SerialPortFunction.TELEMETRY_MSP) {
                    cell.detailTextLabel?.text = "MSP"
                } else if port.functions.contains(SerialPortFunction.TELEMETRY_SMARTPORT) {
                    cell.detailTextLabel?.text = "Smartport"
                } else {
                    cell.detailTextLabel?.text = "Disabled"
                }
                return cell
                
            case 4: // telemetry baudrate
                let cell = tableView.dequeueReusableCellWithIdentifier("TelemetryBaudrateCell")!
                cell.detailTextLabel?.text = port.TELEMETRY_baudrate.name
                return cell

            case 5: // Serial RX
                let cell = tableView.dequeueReusableCellWithIdentifier("SerialRXCell")!
                cell.detailTextLabel?.text = port.functions.contains(SerialPortFunction.RX_SERIAL) ? "Enabled" : "Disabled"
                return cell

                
            case 6: // GPS
                let cell = tableView.dequeueReusableCellWithIdentifier("GPSCell")!
                cell.detailTextLabel?.text = port.functions.contains(SerialPortFunction.GPS) ? port.GPS_baudrate.name : "Disabled"
                return cell

            default:
                log(.Error, "Too many cells in PortConfigViewController secion: \(indexPath.row)")
                return tableView.dequeueReusableCellWithIdentifier("TitleCell")!
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == 0 ? 79 : 44
    }
    
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 || indexPath.row == 0 { return }
        let port = ports[indexPath.section - 1]
        let vc = SelectionTableViewController(style: .Grouped)
        vc.delegate = self
        vc.tag = (indexPath.section - 1) * 7 + indexPath.row - 1
        vc.title = port.name

        switch indexPath.row {
        case 1: // msp
            vc.title! += " MSP"
            vc.items = ["Disabled", "9600", "19200", "38400", "57600", "115200"]

        case 2: // blackbox
            vc.title! += " Blackbox"
            vc.items = ["Disabled", "19200", "38400", "57600", "115200", "230400", "250000"]
            
        case 3: // telemetry type
            vc.title! += " Telemetry"
            vc.items = ["Disabled", "FrSky", "Graupner HOTT", "MSP", "Smartport"]

        case 4: // telemetry baudrate
            vc.title! += " Telemetry Baudrate"
            vc.items = ["AUTO", "9600", "19200", "38400", "57600", "115200"]

        case 5: // Serial RX
            vc.title! += " Serial RX"
            vc.items = ["Disabled", "Enabled"]

        case 6: // GPS
            vc.title! += " GPS"
            vc.items = ["Disabled", "9600", "19200", "38400", "57600", "115200"]

        default:
            print("Too many cells in PortConfigViewController section")
        }

        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    // MARK: - IBActions
    
    @IBAction func save(sender: AnyObject) {
        dataStorage.serialPorts = ports
        
        msp.crunchAndSendMSP(MSP_SET_CF_SERIAL_CONFIG) {
            msp.sendMSP([MSP_EEPROM_WRITE, MSP_SET_REBOOT]) {
                delay(1, callback: self.sendDataRequest) // reload
            }
        }
    }
}