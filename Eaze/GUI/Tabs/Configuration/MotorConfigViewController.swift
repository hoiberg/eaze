//
//  MotorConfigViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 08-12-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

class MotorConfigViewController: GroupedTableViewController, MSPUpdateSubscriber {
    
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
    
    private let mspCodes = [MSP_BF_CONFIG, MSP_MISC] // for all api versions
    private let mspCodes_v1_8 = [MSP_ARMING_CONFIG] // only if api version >= 1.8.0
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addSubscriber(self, forCodes: mspCodes)
        msp.addSubscriber(self, forCodes: mspCodes_v1_8)
        if bluetoothSerial.isConnected {
            sendDataRequest()
        } else {
            saveButton.enabled = false
        }
        
        notificationCenter.addObserver(self, selector: #selector(MotorConfigViewController.serialOpened), name: SerialOpenedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MotorConfigViewController.serialClosed), name: SerialClosedNotification, object: nil)
        
        for field in [minThrottleField, midThrottleField, maxThrottleField, minCommandField] {
            field.maxValue = 2000
            field.minValue = 0
            field.decimal = 0
            field.increment = 1
        }
        
        disarmDelayField.maxValue = 60
        disarmDelayField.minValue = 0
        disarmDelayField.decimal = 0
        disarmDelayField.increment = 1
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        alwaysDisarmSwitch.enabled = dataStorage.apiVersion >= "1.8.0" ? true : false
        disarmDelayField.enabled = dataStorage.apiVersion >= "1.8.0" ? true : false
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    
    // MARK: Data request / update
    
    func sendDataRequest() {
        msp.sendMSP(mspCodes)
        if dataStorage.apiVersion >= "1.8.0" {
            msp.sendMSP(mspCodes_v1_8)
        }
    }
    
    func mspUpdated(code: Int) {
        switch code {
        case MSP_BF_CONFIG:
            motorStopSwitch.on = dataStorage.BFFeatures.bitCheck(4)
            oneShotSwitch.on = dataStorage.BFFeatures.bitCheck(18)
            
        case MSP_MISC:
            minThrottleField.intValue = dataStorage.minThrottle
            midThrottleField.intValue = dataStorage.midRc
            maxThrottleField.intValue = dataStorage.maxThrottle
            minCommandField.intValue = dataStorage.minCommand
            
        case MSP_ARMING_CONFIG:
            alwaysDisarmSwitch.on = dataStorage.disarmKillsSwitch
            disarmDelayField.intValue = dataStorage.autoDisarmDelay
            
            
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
    
    
    // MARK: IBActions
    
    @IBAction func save(sender: AnyObject) {
        
        dataStorage.BFFeatures.setBit(4, value: Int(motorStopSwitch.on))
        dataStorage.BFFeatures.setBit(18, value: Int(oneShotSwitch.on))
        msp.crunchAndSendMSP(MSP_SET_BF_CONFIG)
        
        dataStorage.minThrottle = minThrottleField.intValue
        dataStorage.midRc = midThrottleField.intValue
        dataStorage.maxThrottle = maxThrottleField.intValue
        dataStorage.minCommand = minCommandField.intValue
        msp.crunchAndSendMSP(MSP_SET_MISC)
        
        if dataStorage.apiVersion >= "1.8.0" {
            dataStorage.disarmKillsSwitch = alwaysDisarmSwitch.on
            dataStorage.autoDisarmDelay = disarmDelayField.intValue
            msp.crunchAndSendMSP(MSP_SET_ARMING_CONFIG)
        }
        
        msp.sendMSP(MSP_EEPROM_WRITE)
    }
}