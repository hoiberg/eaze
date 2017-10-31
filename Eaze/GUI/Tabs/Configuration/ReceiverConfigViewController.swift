//
//  GeneralConfigViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 23-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

final class ReceiverConfigViewController: GroupedTableViewController, SelectionTableViewControllerDelegate, MSPUpdateSubscriber, UITextFieldDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var channelMapField: UITextField!
    @IBOutlet weak var receiverModeLabel: UILabel!
    @IBOutlet weak var serialReceiverLabel: UILabel!
    @IBOutlet weak var failsafeSwitch: UISwitch!
    @IBOutlet weak var failsafeThrottleField: StaticAdjustableTextField!
    @IBOutlet weak var analogRSSISwitch: UISwitch!
    @IBOutlet weak var RSSIInputChannelLabel: UILabel!
    
    
    // MARK: - Variables
    
    fileprivate let mspCodes = [MSP_BF_CONFIG, MSP_RC, MSP_RX_MAP, MSP_MISC, MSP_RX_CONFIG, MSP_FEATURE],
                    receiverModes = ["PPM", "Serial", "Parallel PWM", "MSP"]
    
    fileprivate var serialReceiverModes = ["SPEKTRUM1024", "SPEKTRUM2048", "SBUS", "SUMD", "SUMH", "XBUS_MODE_B", "XBUS_MODE_B_RJ01", "IBUS"],
                    RSSIInputChannels = ["Disabled"],
                    lastValid_RC_MAP = "AETR1234"
    
    fileprivate var selectedSerialReceiverMode = 0  {
        didSet {
            serialReceiverLabel.text = serialReceiverModes[selectedSerialReceiverMode]
        }
    }
    
    fileprivate var selectedReceiverMode = 2  {
        didSet {
            receiverModeLabel.text = receiverModes[selectedReceiverMode]
        }
    }
    
    fileprivate var selectedRSSIInputChannel = 0 {
        didSet {
            RSSIInputChannelLabel.text = RSSIInputChannels[selectedRSSIInputChannel]
        }
    }
    
    
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
        
        failsafeThrottleField.maxValue = 2000
        failsafeThrottleField.minValue = 0
        failsafeThrottleField.decimal = 0
        failsafeThrottleField.increment = 1
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    

    // MARK: Data request / update
    
    func sendDataRequest() {
        var codes = mspCodes
        
        if _bf_config_depreciated {
            codes.removeObject(MSP_BF_CONFIG)
        } else {
            codes.removeObjects([MSP_RX_CONFIG, MSP_FEATURE])
        }
        
        msp.sendMSP(codes)
    }
    
    func mspUpdated(_ code: Int) {
        switch code {
        case MSP_BF_CONFIG:
            if dataStorage.BFFeatures.bitCheck(0) {
                selectedReceiverMode = 0
            } else if dataStorage.BFFeatures.bitCheck(13) {
                selectedReceiverMode = 2
            } else if dataStorage.BFFeatures.bitCheck(14) {
                selectedReceiverMode = 3
            } else {
                selectedReceiverMode = 1 // pwm (default I guess)
            }
            failsafeSwitch.isOn = dataStorage.BFFeatures.bitCheck(8)
            analogRSSISwitch.isOn = dataStorage.BFFeatures.bitCheck(15)
            selectedSerialReceiverMode = dataStorage.serialRXType
            
        case MSP_MISC:
            selectedRSSIInputChannel = dataStorage.rssiChannel
            failsafeThrottleField.intValue = dataStorage.failsafeThrottle

        case MSP_RC:
            if selectedRSSIInputChannel >= dataStorage.activeChannels {
                selectedRSSIInputChannel = 0 // in case the MSP_MISC update hasn't arrived yet
            }
            RSSIInputChannels = ["Disabled"]
            for i in 1 ... dataStorage.activeChannels {
                RSSIInputChannels.append("\(i)")
            }
            
        case MSP_RX_MAP:
            let letters = "AERT1234"
            var str = ""
            for i in 0 ..< dataStorage.RC_MAP.count {
                str += letters[dataStorage.RC_MAP.index(of: i)!]
            }
            channelMapField.text = str
            lastValid_RC_MAP = str
            
        case MSP_RX_CONFIG:
            selectedSerialReceiverMode = dataStorage.serialRXType

        case MSP_FEATURE:
            if dataStorage.BFFeatures.bitCheck(0) {
                selectedReceiverMode = 0
            } else if dataStorage.BFFeatures.bitCheck(13) {
                selectedReceiverMode = 2
            } else if dataStorage.BFFeatures.bitCheck(14) {
                selectedReceiverMode = 3
            } else {
                selectedReceiverMode = 1 // pwm (default I guess)
            }
            failsafeSwitch.isOn = dataStorage.BFFeatures.bitCheck(8)
            analogRSSISwitch.isOn = dataStorage.BFFeatures.bitCheck(15)

            
        default:
            log(.Warn, "ReceiverConfigViewController received MSP code not subscribed to: \(code)")
        }
    }
    
    
    // MARK: Serial events
    
    @objc func serialOpened() {
        if isBeingShown {
            sendDataRequest()
        }
        
        saveButton.isEnabled = true
        
        if dataStorage.apiVersion >= "1.15.0" {
            // new failsafe setup not yet supported
            failsafeSwitch.isEnabled = false
            failsafeThrottleField.enabled = false
        } else {
            failsafeSwitch.isEnabled = true
            failsafeThrottleField.enabled = true
        }
    }
    
    @objc func serialClosed() {
        saveButton.isEnabled = false
    }
    
    
    // MARK: TableView delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                // Receiver mode
                let vc = SelectionTableViewController(style: .grouped)
                vc.tag = 0
                vc.title = "Receiver Mode"
                vc.items = receiverModes
                vc.selectedItem = selectedReceiverMode
                vc.delegate = self
                navigationController?.pushViewController(vc, animated: true)
                
            } else if indexPath.row == 2 {
                // Serial Receiver mode
                let vc = SelectionTableViewController(style: .grouped)
                vc.tag = 1
                vc.title = "Serial Receiver Provider"
                vc.items = serialReceiverModes
                vc.selectedItem = selectedSerialReceiverMode
                vc.delegate = self
                
                if dataStorage.apiVersion < "1.15.0" {
                    vc.items.removeObject("IBUS")
                }

                navigationController?.pushViewController(vc, animated: true)
            }
            
        } else if indexPath.section == 2 && indexPath.row == 0 {
            // RSSI channel
            let vc = SelectionTableViewController(style: .grouped)
            vc.tag = 2
            vc.title = "RSSI Input Channel"
            vc.items = RSSIInputChannels
            vc.selectedItem = selectedRSSIInputChannel
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    // MARK: UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // allow backspace
        if string.isEmpty { return true }
        
        // only allow AERT1234 to be put in the textfield
        if string.rangeOfCharacter(from: CharacterSet(charactersIn: "AERT1234").inverted) != nil { return false }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // check that the new value of channelMapField is valid
        if textField.text!.characters.count != 8 {
            textField.text = lastValid_RC_MAP
            return
        }
        
        var duplicityBuffer = ""
        for channel in textField.text!.characters {
            if duplicityBuffer.indexOfCharacter(channel) == nil {
                duplicityBuffer.append(channel)
            } else {
                textField.text = lastValid_RC_MAP
                return
            }
        }
        
        lastValid_RC_MAP = textField.text!
    }
    
    
    // MARK: SelectionTableViewControllerDelegate
    
    func selectionTableWithTag(_ tag: Int, didSelectItem item: Int) {
        if tag == 0 {
            selectedReceiverMode = item
        } else if tag == 1 {
            selectedSerialReceiverMode = item
        } else {
            selectedRSSIInputChannel = item
        }
    }
    
    
    // MARK: IBActions
    
    @IBAction func save(_ sender: AnyObject) {
        var codes = [Int]()

        if selectedReceiverMode == 0 {
            dataStorage.BFFeatures.setBit(0, value: 1)
            dataStorage.BFFeatures.setBit(3, value: 0)
            dataStorage.BFFeatures.setBit(13, value: 0)
            dataStorage.BFFeatures.setBit(14, value: 0)
        } else if selectedReceiverMode == 1 {
            dataStorage.BFFeatures.setBit(0, value: 0)
            dataStorage.BFFeatures.setBit(3, value: 1)
            dataStorage.BFFeatures.setBit(13, value: 0)
            dataStorage.BFFeatures.setBit(14, value: 0)
        } else if selectedReceiverMode == 2 {
            dataStorage.BFFeatures.setBit(0, value: 0)
            dataStorage.BFFeatures.setBit(3, value: 0)
            dataStorage.BFFeatures.setBit(13, value: 1)
            dataStorage.BFFeatures.setBit(14, value: 0)
        } else if selectedReceiverMode == 3 {
            dataStorage.BFFeatures.setBit(0, value: 0)
            dataStorage.BFFeatures.setBit(3, value: 0)
            dataStorage.BFFeatures.setBit(13, value: 0)
            dataStorage.BFFeatures.setBit(14, value: 1)
        }
        
        dataStorage.BFFeatures.setBit(8, value: failsafeSwitch.isOn ? 1 : 0)
        dataStorage.BFFeatures.setBit(15, value: analogRSSISwitch.isOn ? 1 : 0)
        dataStorage.serialRXType = selectedSerialReceiverMode
        
        if _bf_config_depreciated {
            codes += [MSP_SET_RX_CONFIG, MSP_SET_FEATURE]
        } else {
            codes.append(MSP_SET_BF_CONFIG)
        }
        
        dataStorage.rssiChannel = selectedRSSIInputChannel
        dataStorage.failsafeThrottle = failsafeThrottleField.intValue
        codes.append(MSP_SET_MISC)
        
        let letters = "AERT1234"
        var map: [Int] = []
        for c in letters.characters {
            map.append(channelMapField.text!.indexOfCharacter(c)!)
        }
        dataStorage.RC_MAP = map
        codes.append(MSP_SET_RX_MAP)
        
        msp.crunchAndSendMSP(codes) {
            msp.sendMSP(MSP_EEPROM_WRITE, callback: self.sendDataRequest) // save & reload
        }
    }
}
