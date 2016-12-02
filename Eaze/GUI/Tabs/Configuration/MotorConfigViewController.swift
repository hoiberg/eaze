//
//  MotorConfigViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 08-12-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

final class MotorConfigViewController: GroupedTableViewController, MSPUpdateSubscriber {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var motorStopSwitch: UISwitch!
    @IBOutlet weak var oneShotSwitch: UISwitch!
    @IBOutlet weak var alwaysDisarmSwitch: UISwitch!
    @IBOutlet weak var minThrottleField: StaticAdjustableTextField!
    @IBOutlet weak var midThrottleField: StaticAdjustableTextField!
    @IBOutlet weak var maxThrottleField: StaticAdjustableTextField!
    @IBOutlet weak var minCommandField: StaticAdjustableTextField!
    @IBOutlet weak var disarmDelayField: StaticAdjustableTextField!
    
    
    // MARK: - Variables
    
    fileprivate let mspCodes = [MSP_BF_CONFIG, MSP_MISC, MSP_ARMING_CONFIG, MSP_FEATURE]
    
    
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
        
        for field in [minThrottleField, maxThrottleField, minCommandField] {
            field?.maxValue = 2000
            field?.minValue = 0
            field?.decimal = 0
            field?.increment = 1
        }
        
        midThrottleField.maxValue = 1599
        midThrottleField.minValue = 1401
        midThrottleField.decimal = 0
        midThrottleField.increment = 1
        
        disarmDelayField.maxValue = 60
        disarmDelayField.minValue = 0
        disarmDelayField.decimal = 0
        disarmDelayField.increment = 1
        disarmDelayField.suffix = "s"
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    
    // MARK: Data request / update
    
    func sendDataRequest() {
        var codes = mspCodes

        if dataStorage.apiVersion < "1.8.0" {
            codes.removeObject(MSP_ARMING_CONFIG)
        }

        if _bf_config_depreciated {
            codes.removeObject(MSP_BF_CONFIG)
        } else {
            codes.removeObject(MSP_FEATURE)
        }
        
        msp.sendMSP(codes)
    }
    
    func mspUpdated(_ code: Int) {
        switch code {
        case MSP_BF_CONFIG:
            motorStopSwitch.isOn = dataStorage.BFFeatures.bitCheck(4)
            oneShotSwitch.isOn = dataStorage.BFFeatures.bitCheck(18)
            
        case MSP_MISC:
            minThrottleField.intValue = dataStorage.minThrottle
            midThrottleField.intValue = dataStorage.midRc
            maxThrottleField.intValue = dataStorage.maxThrottle
            minCommandField.intValue = dataStorage.minCommand
            
        case MSP_ARMING_CONFIG:
            alwaysDisarmSwitch.isOn = dataStorage.disarmKillsSwitch
            disarmDelayField.intValue = dataStorage.autoDisarmDelay
            
        case MSP_FEATURE:
            motorStopSwitch.isOn = dataStorage.BFFeatures.bitCheck(4)
            oneShotSwitch.isOn = dataStorage.BFFeatures.bitCheck(18)
            
        default:
            log(.Warn, "MotorConfigViewController received MSP code not subscribed to: \(code)")
        }
    }
    
    
    // MARK: Serial events
    
    func serialOpened() {
        if isBeingShown {
            sendDataRequest()
        }
        
        saveButton.isEnabled = true
        alwaysDisarmSwitch.isEnabled = dataStorage.apiVersion >= "1.8.0" ? true : false
        disarmDelayField.enabled = dataStorage.apiVersion >= "1.8.0" ? true : false
    }
    
    func serialClosed() {
        saveButton.isEnabled = false
    }
    
    
    // MARK: IBActions
    
    @IBAction func save(_ sender: AnyObject) {
        var codes = [Int]()
        dataStorage.BFFeatures.setBit(4, value: motorStopSwitch.isOn ? 1 : 0)
        dataStorage.BFFeatures.setBit(18, value: oneShotSwitch.isOn ? 1 : 0)
        if _bf_config_depreciated {
            codes.append(MSP_SET_FEATURE)
        } else {
            codes.append(MSP_SET_BF_CONFIG)
        }
        
        dataStorage.minThrottle = minThrottleField.intValue
        dataStorage.midRc = midThrottleField.intValue
        dataStorage.maxThrottle = maxThrottleField.intValue
        dataStorage.minCommand = minCommandField.intValue
        codes.append(MSP_SET_MISC)
        
        if dataStorage.apiVersion >= "1.8.0" {
            dataStorage.disarmKillsSwitch = alwaysDisarmSwitch.isOn
            dataStorage.autoDisarmDelay = disarmDelayField.intValue
            codes.append(MSP_SET_ARMING_CONFIG)
        }
        
        msp.crunchAndSendMSP(codes) {
            msp.sendMSP(MSP_EEPROM_WRITE, callback: self.sendDataRequest)
        }
    }
}
