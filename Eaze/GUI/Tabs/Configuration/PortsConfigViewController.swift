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
    
    fileprivate let mspCodes = [MSP_CF_SERIAL_CONFIG]
    fileprivate var ports = [SerialPortConfig()] // Working copy of dataStorage's serialPorts, first contains sample port to satisfy the Apple App Review team
    

    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addSubscriber(self, forCodes: mspCodes)
        
        if bluetoothSerial.isConnected {
            sendDataRequest()
            serialOpened()
        } else {
            serialClosed()
        }
        
        notificationCenter.addObserver(self, selector: #selector(serialOpened), name: Notification.Name.Serial.opened, object: nil)
        notificationCenter.addObserver(self, selector: #selector(serialClosed), name: Notification.Name.Serial.closed, object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    
    // MARK: Data request / update
    
    func sendDataRequest() {
        msp.sendMSP(mspCodes)
    }
    
    func mspUpdated(_ code: Int) {
        switch code {
        case MSP_CF_SERIAL_CONFIG:
            ports = dataStorage.serialPorts.deepCopy()
            tableView.reloadData()
            
        default:
            log(.Warn, "PortsConfigViewController received MSP code not subscribed to: \(code)")
        }
    }
    
    
    // MARK: - Serial events
    
    func serialOpened() {
        if dataStorage.apiVersion >= "1.6.0" {
            if isBeingShown {
                sendDataRequest()
            }
            
            saveButton.isEnabled = true
        } else {
            ports = []
            saveButton.isEnabled = false
            tableView.reloadData()
        }
    }
    
    func serialClosed() {
        saveButton.isEnabled = false
    }
    
    
    // MARK: SelectionTableViewControllerDelegate
    
    func selectionTableWithTag(_ tag: Int, didSelectItem item: Int) {
        let port = ports[Int(floor(Float(tag) / 7.0))]
        let row = tag % 7
        
        switch row {
        case 0: // msp
            if item == 0 { // disabled
                port.functions.removeObject(.msp)
            } else { // enabled, add if it doesn't exist already
                port.functions.appendIfNonexistent(.msp)
                let options: [Baudrate] = [.b9600, .b19200, .b38400, .b57600, .b115200]
                port.MSP_baudrate = options[item - 1]
            }
            
        case 1: // blackbox
            if item == 0 { // disabled
                port.functions.removeObject(.blackbox)
            } else { // enabled, add if it doesn't exist already
                port.functions.appendIfNonexistent(.blackbox)
                let options: [Baudrate] = [.b19200, .b38400, .b57600, .b115200, .b230400, .b250000]
                port.BLACKBOX_baudrate = options[item - 1]
            }
            
        case 2: // telemetry type
            // first remove all, then add the new one
            port.functions.removeObjects([.telemetry_FRSKY, .telemetry_HOTT, .telemetry_MSP_LTM, .telemetry_SMARTPORT, .telemetry_MAVLINK])
            if item > 0 {
                let options: [SerialPortFunction] = [.telemetry_FRSKY, .telemetry_HOTT, .telemetry_MSP_LTM, .telemetry_SMARTPORT, .telemetry_MAVLINK]
                port.functions.append(options[item - 1])
            }
            
        case 3: // telemetry baudrate
            let options: [Baudrate] = [.auto, .b9600, .b19200, .b38400, .b57600, .b115200]
            port.TELEMETRY_baudrate = options[item]
            
        case 4: // Serial RX
            if item == 0 {
                port.functions.removeObject(.rx_SERIAL)
            } else {
                port.functions.appendIfNonexistent(.rx_SERIAL)
            }
            
        case 5: // GPS
            if item == 0 { // disabled
                port.functions.removeObject(.gps)
            } else { // enabled, add if it doesn't exist already
                port.functions.appendIfNonexistent(.gps)
                let options: [Baudrate] = [.b9600, .b19200, .b38400, .b57600, .b115200]
                port.GPS_baudrate = options[item - 1]
            }
            
        default:
            log(.Warn, "PortsConfigurationViewController: item value too high (\(row))")
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + ports.count // one for the message cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 7
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // return the right cell
        if indexPath.section == 0 {
            // message cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell")!
            if dataStorage.apiVersion == "0.0.0" || dataStorage.apiVersion >= "1.6.0" {
                (cell.viewWithTag(1) as! UILabel).text = UIDevice.isPhone ?
                    "Not all combinations are valid. When the flight controller detects this the serial port configuration will be reset. Do not disable MSP on the first serial port unless unless you know what you are doing!" :
                    "Note: Not all combinations are valid. When the flight controller detects this the serial port configuration will be reset.\nNote: Do not disable MSP on the first serial port unless unless you know what you are doing!"
            } else {
                (cell.viewWithTag(1) as! UILabel).text = "Serial port configuration requires Cleanflight 1.6.0 or higher, you are running \(dataStorage.apiVersion.stringValue)"
            }
            return cell
        } else {
            if ports.count < indexPath.section {
                log(.Error, "Too many sections (\(indexPath.section)) in PortConfigViewController! This should not be possible.")
                return tableView.dequeueReusableCell(withIdentifier: "TitleCell")!
            }
            
            let port = ports[indexPath.section - 1]
            switch indexPath.row {
            case 0: // title
                let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell")!
                (cell.viewWithTag(1) as! UILabel).text = port.name
                return cell
                
            case 1: // msp
                let cell = tableView.dequeueReusableCell(withIdentifier: "MSPCell")!
                cell.detailTextLabel?.text = port.functions.contains(.msp) ? port.MSP_baudrate.name : "Disabled"
                return cell
                
            case 2: // blackbox
                let cell = tableView.dequeueReusableCell(withIdentifier: "BlackboxCell")!
                cell.detailTextLabel?.text = port.functions.contains(SerialPortFunction.blackbox) ? port.BLACKBOX_baudrate.name : "Disabled"
                return cell

            case 3: // telemetry type
                let cell = tableView.dequeueReusableCell(withIdentifier: "TelemetryCell")!
                if port.functions.contains(.telemetry_FRSKY) {
                    cell.detailTextLabel?.text = "FrSky"
                } else if port.functions.contains(.telemetry_HOTT) {
                    cell.detailTextLabel?.text = "Graupner HOTT"
                } else if port.functions.contains(.telemetry_MSP_LTM) {
                    cell.detailTextLabel?.text = dataStorage.apiVersion >= "1.15.0" ? "LTM" : "MSP"
                } else if port.functions.contains(.telemetry_SMARTPORT) {
                    cell.detailTextLabel?.text = "Smartport"
                } else if port.functions.contains(.telemetry_MAVLINK) {
                    cell.detailTextLabel?.text = "MAVLink"
                } else {
                    cell.detailTextLabel?.text = "Disabled"
                }
                return cell
                
            case 4: // telemetry baudrate
                let cell = tableView.dequeueReusableCell(withIdentifier: "TelemetryBaudrateCell")!
                cell.detailTextLabel?.text = port.TELEMETRY_baudrate.name
                return cell

            case 5: // Serial RX
                let cell = tableView.dequeueReusableCell(withIdentifier: "SerialRXCell")!
                cell.detailTextLabel?.text = port.functions.contains(SerialPortFunction.rx_SERIAL) ? "Enabled" : "Disabled"
                return cell

                
            case 6: // GPS
                let cell = tableView.dequeueReusableCell(withIdentifier: "GPSCell")!
                cell.detailTextLabel?.text = port.functions.contains(SerialPortFunction.gps) ? port.GPS_baudrate.name : "Disabled"
                return cell

            default:
                log(.Error, "Too many cells in PortConfigViewController secion: \(indexPath.row)")
                return tableView.dequeueReusableCell(withIdentifier: "TitleCell")!
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 79 : 44
    }
    
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 || indexPath.row == 0 { return }
        let port = ports[indexPath.section - 1]
        let vc = SelectionTableViewController(style: .grouped)
        vc.delegate = self
        vc.tag = (indexPath.section - 1) * 7 + indexPath.row - 1
        vc.title = port.name + " "

        switch indexPath.row {
        case 1: // msp
            vc.title! += "MSP"
            vc.items = ["Disabled", "9600", "19200", "38400", "57600", "115200"]
            let options: [Baudrate] = [.b9600, .b19200, .b38400, .b57600, .b115200]
            vc.selectedItem = port.functions.contains(.msp) ? options.index(of: port.MSP_baudrate)! + 1 : 0

        case 2: // blackbox
            vc.title! += "Blackbox"
            vc.items = ["Disabled", "19200", "38400", "57600", "115200", "230400", "250000"]
            let options: [Baudrate] = [.b19200, .b38400, .b57600, .b115200, .b230400, .b250000]
            vc.selectedItem = port.functions.contains(.blackbox) ? options.index(of: port.BLACKBOX_baudrate)! + 1 : 0
            
        case 3: // telemetry type
            vc.title! += "Telemetry"
            vc.items = ["Disabled", "FrSky", "Graupner HOTT", dataStorage.apiVersion >= "1.15.0" ? "LTM" : "MSP", "Smartport"] + (dataStorage.apiVersion >= "1.18.0" ? ["MAVLink"] : [])
            let options: [SerialPortFunction] = [.telemetry_FRSKY, .telemetry_HOTT, .telemetry_MSP_LTM, .telemetry_SMARTPORT, .telemetry_MAVLINK]
            for function in port.functions {
                vc.selectedItem = options.contains(function) ? options.index(of: function)! + 1 : 0
            }

        case 4: // telemetry baudrate
            vc.title! += "Telemetry Baudrate"
            vc.items = ["AUTO", "9600", "19200", "38400", "57600", "115200"]
            let options: [Baudrate] = [.auto, .b9600, .b19200, .b38400, .b57600, .b115200]
            vc.selectedItem = options.index(of: port.TELEMETRY_baudrate)!


        case 5: // Serial RX
            vc.title! += "Serial RX"
            vc.items = ["Disabled", "Enabled"]
            vc.selectedItem = port.functions.contains(.rx_SERIAL) ? 1 : 0

        case 6: // GPS
            vc.title! += "GPS"
            vc.items = ["Disabled", "9600", "19200", "38400", "57600", "115200"]
            let options: [Baudrate] = [.b9600, .b19200, .b38400, .b57600, .b115200]
            vc.selectedItem = port.functions.contains(.gps) ? options.index(of: port.GPS_baudrate)! + 1 : 0

        default:
            print("Too many cells in PortConfigViewController section")
        }

        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    // MARK: - IBActions
    
    @IBAction func save(_ sender: AnyObject) {
        dataStorage.serialPorts = ports.deepCopy()
        
        msp.crunchAndSendMSP(MSP_SET_CF_SERIAL_CONFIG) {
            msp.sendMSP([MSP_EEPROM_WRITE, MSP_SET_REBOOT]) {
                delay(1, callback: self.sendDataRequest) // reload
            }
        }
    }
}
