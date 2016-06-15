//
//  GeneralConfigViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 23-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

class ReceiverConfigViewController: GroupedTableViewController, SelectionTableViewControllerDelegate, MSPUpdateSubscriber, UITextFieldDelegate {
    
    
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
    
    private let mspCodes = [MSP_BF_CONFIG, MSP_RC, MSP_RX_MAP, MSP_MISC]
    private let serialReceiverModes = ["SPEKTRUM1024", "SPEKTRUM2048", "SBUS", "SUMD", "SUMH", "XBUS_MODE_B", "XBUS_MODE_B_RJ01"]
    private let receiverModes = ["PPM", "Serial", "Parallel PWM", "MSP"]
    private var RSSIInputChannels = ["Disabled"]
    private var lastValid_RC_MAP = "AETR1234"
    
    private var selectedSerialReceiverMode = 0  {
        didSet {
            serialReceiverLabel.text = serialReceiverModes[selectedSerialReceiverMode]
        }
    }
    private var selectedReceiverMode = 0  {
        didSet {
            receiverModeLabel.text = receiverModes[selectedReceiverMode]
        }
    }
    private var selectedRSSIInputChannel = 0 {
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
        } else {
            saveButton.enabled = false
        }
        
        notificationCenter.addObserver(self, selector: #selector(ReceiverConfigViewController.serialOpened), name: SerialOpenedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ReceiverConfigViewController.serialClosed), name: SerialClosedNotification, object: nil)
        
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
        msp.sendMSP(mspCodes)
    }
    
    func mspUpdated(code: Int) {
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
            failsafeSwitch.on = dataStorage.BFFeatures.bitCheck(8)
            analogRSSISwitch.on = dataStorage.BFFeatures.bitCheck(15)
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
                str.append(letters[dataStorage.RC_MAP.indexOf(i)!])
            }
            channelMapField.text = str
            lastValid_RC_MAP = str
            
        default:
            print("Received MSP update not subscribed to")
        }
    }
    
    
    // MARK: Serial events
    
    func serialOpened() {
        sendDataRequest()
        saveButton.enabled = true
    }
    
    func serialClosed() {
        saveButton.enabled = false
    }
    
    
    // MARK: TableView delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                // Receiver mode
                let vc = SelectionTableViewController(style: .Grouped)
                vc.tag = 0
                vc.title = "Receiver Mode"
                vc.items = receiverModes
                vc.delegate = self
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 2 {
                // Serial Receiver mode
                let vc = SelectionTableViewController(style: .Grouped)
                vc.tag = 1
                vc.title = "Serial Receiver Provider"
                vc.items = serialReceiverModes
                vc.delegate = self
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if indexPath.section == 2 && indexPath.row == 1 {
            // RSSI channel
            let vc = SelectionTableViewController(style: .Grouped)
            vc.tag = 2
            vc.title = "RSSI Input Channel"
            vc.items = RSSIInputChannels
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    // MARK: UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // allow backspace
        if string.isEmpty { return true }
        
        // only allow AERT1234 to be put in the textfield
        if string.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "AERT1234").invertedSet) != nil { return false }
        
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
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
    
    func selectionTableWithTag(tag: Int, didSelectItem item: Int) {
        if tag == 0 {
            selectedReceiverMode = item
        } else if tag == 1 {
            selectedSerialReceiverMode = item
        } else {
            selectedRSSIInputChannel = item
        }

    }
    
    
    // MARK: IBActions
    
    @IBAction func save(sender: AnyObject) {

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
        dataStorage.BFFeatures.setBit(8, value: Int(failsafeSwitch.on))
        dataStorage.BFFeatures.setBit(15, value: Int(analogRSSISwitch.on))
        dataStorage.serialRXType = selectedSerialReceiverMode
        msp.crunchAndSendMSP(MSP_SET_BF_CONFIG)
        
        dataStorage.rssiChannel = selectedRSSIInputChannel
        dataStorage.failsafeThrottle = failsafeThrottleField.intValue
        msp.crunchAndSendMSP(MSP_SET_MISC)
        
        let letters = "AERT1234"
        var map: [Int] = []
        for c in letters.characters {
            map.append(channelMapField.text!.indexOfCharacter(c)!)
        }
        dataStorage.RC_MAP = map
        msp.crunchAndSendMSP(MSP_RX_MAP)
        
        msp.sendMSP(MSP_EEPROM_WRITE)
    }
}