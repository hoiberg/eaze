//
//  GeneralConfigViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 23-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

// TODO: MSP_v1_8_0 ??

import UIKit

class GeneralConfigViewController: GroupedTableViewController, SelectionTableViewControllerDelegate, MSPUpdateSubscriber, StaticAdjustableTextFieldDelegate {
    
    // MARK: - IBOutlets

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var calibrateAccLabel: UILabel!
    @IBOutlet weak var calibrateMagLabel: UILabel!
    @IBOutlet weak var resetLabel: UILabel!
    @IBOutlet weak var mixerTypeLabel: UILabel!
    @IBOutlet weak var rollAdjustment: StaticAdjustableTextField!
    @IBOutlet weak var pitchAdjustment: StaticAdjustableTextField!
    @IBOutlet weak var yawAdjustment: StaticAdjustableTextField!
    @IBOutlet weak var rollAccTrim: StaticAdjustableTextField!
    @IBOutlet weak var pitchAccTrim: StaticAdjustableTextField!
    @IBOutlet weak var loopTime: StaticAdjustableTextField!
    @IBOutlet weak var hertzLabel: UILabel!
    
    
    // MARK: - Variables
    
    private let mspCodes = [MSP_BF_CONFIG, MSP_ACC_TRIM, MSP_LOOP_TIME, MSP_STATUS] // msp codes send for this view
    //private let mspCodesSub = [MSP_API_VERSION] // msp codes only subscribed to NIET!!!!!!!!!!!!!!!!!!!!!!
    //private let mspCodes_v1_8 = [MSP_LOOP_TIME]
    private var selectedMixerConfiguration = 0
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addSubscriber(self, forCodes: mspCodes)
        //msp.addSubscriber(self, forCodes: mspCodes_v1_8)
        if bluetoothSerial.isConnected {
            sendDataRequest()
            saveButton.enabled = true
            calibrateAccLabel.enabled = true
            calibrateMagLabel.enabled = false
            resetLabel.enabled = true
        } else {
            saveButton.enabled = false
            calibrateAccLabel.enabled = false
            calibrateMagLabel.enabled = false
            resetLabel.enabled = false
        }
        
        notificationCenter.addObserver(self, selector: #selector(GeneralConfigViewController.serialOpened), name: SerialOpenedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(GeneralConfigViewController.serialClosed), name: SerialClosedNotification, object: nil)

        
        for field in [rollAdjustment, pitchAdjustment, yawAdjustment] {
            field.maxValue = 360
            field.minValue = -180
            field.decimal = 0
            field.increment = 1
        }
        
        for field in [rollAccTrim, pitchAccTrim] {
            field.maxValue = 300
            field.minValue = -300
            field.decimal = 0
            field.increment = 1
        }
        
        loopTime.intValue = 3500
        loopTime.maxValue = 9000
        loopTime.minValue = 0
        loopTime.decimal = 0
        loopTime.increment = 100
        loopTime.delegate = self

    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    
    // MARK: Data request / update
    
    func sendDataRequest() {
        msp.sendMSP(mspCodes)
        /*if dataStorage.apiVersion >= "1.8.0" {
            msp.sendMSP(mspCodes_v1_8)
        }*/
    }
    
    func mspUpdated(code: Int) {
        switch code {
        case MSP_BF_CONFIG:
            selectedMixerConfiguration = dataStorage.mixerConfiguration
            mixerTypeLabel.text = mixerList[dataStorage.mixerConfiguration].name
            rollAdjustment.intValue = dataStorage.boardAlignRoll
            pitchAdjustment.intValue = dataStorage.boardAlignPitch
            yawAdjustment.intValue = dataStorage.boardAlignYaw
            
        case MSP_ACC_TRIM:
            rollAccTrim.intValue = dataStorage.accTrimRoll
            pitchAccTrim.intValue = dataStorage.accTrimPitch
            
        case MSP_LOOP_TIME:
            loopTime.intValue = dataStorage.loopTime
            
        case MSP_STATUS:
            if dataStorage.activeSensors.bitCheck(2) {
                calibrateMagLabel.enabled = true
            }
            
        default:
            print("Received MSP update not subscribed to")
        }
    }
    
    
    // MARK: Serial events
    
    func serialOpened() {
        sendDataRequest()
        saveButton.enabled = true
        calibrateAccLabel.enabled = true
        calibrateMagLabel.enabled = false
        resetLabel.enabled = true
    }
    
    func serialClosed() {
        saveButton.enabled = false
        calibrateAccLabel.enabled = false
        calibrateMagLabel.enabled = false
        resetLabel.enabled = false
    }
    
    
    // MARK: AdjustableTextFieldDelegate
    
    func staticAdjustableTextFieldChangedValue(field: StaticAdjustableTextField) {
        if field == loopTime {
            // update hertz label
            if field.intValue <= 0 {
                hertzLabel.text = "Max"
            } else {
                hertzLabel.text = "\(Int((1.0/field.doubleValue) * 1000000.0))"
            }
        }
    }
    
    
    // MARK: TableView delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                // calibrate acc
                let alert = UIAlertController(title: "Accelerometer Calibration", message: "Place board or frame on leveled surface, then tap 'Proceed'. Ensure platform is not moving during calibration", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Proceed", style: .Default) { _ in
                    log("Initiating ACC calibration")
                    MessageView.showProgressHUD()
                    var success = false
                    delay(4) {
                        guard !success else { return }
                        log("ACC calibration timeout")
                        MessageView.hideProgressHUD()
                    }
                    msp.sendMSP(MSP_ACC_CALIBRATION) {
                        success = true
                        delay(3) {
                            MessageView.hideProgressHUD()
                            MessageView.show("Calibration Successful!")
                        }
                    }})
                presentViewController(alert, animated: true, completion: nil)
            } else if indexPath.row == 1 {
                // calibrate mag
                guard dataStorage.activeSensors.bitCheck(2) else { return }
                let alert = UIAlertController(title: "Compass Calibration", message: "Move multirotor at least 360º on all axis of rotation, within 30 seconds", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Proceed", style: .Default) { _ in
                    log("Initiating MAG calibration")
                    MessageView.showProgressHUD()
                    var success = false
                    delay(4) {
                        guard !success else { return }
                        log("MAG calibration timeout")
                        MessageView.hideProgressHUD()
                    }
                    msp.sendMSP(MSP_MAG_CALIBRATION) {
                        success = true
                        delay(30) {
                            MessageView.hideProgressHUD()
                            MessageView.show("Calibration Successful!")
                        }
                    }})
                presentViewController(alert, animated: true, completion: nil)
            } else {
                // reset
                let alert = UIAlertController(title: "Restore settings to defaults", message: "All current configuration settings will be lost. Continue?", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Proceed", style: .Destructive) { _ in
                    log("Initiating reset to defaults")
                    msp.sendMSP(MSP_RESET_CONF) {
                        MessageView.show("Reset Successful")
                        dataStorage = DataStorage() // reset all settings, go to the dashboard, disconnect, and reconnect
                        self.tabBarController!.selectedIndex = 0 // because this is the easiest way to reset all vc's
                        let prevPeripheral = bluetoothSerial.connectedPeripheral!
                        bluetoothSerial.disconnect()
                        delay(0.5) {
                            bluetoothSerial.connectToPeripheral(prevPeripheral)
                        }
                    }})
                presentViewController(alert, animated: true, completion: nil)
            }
        } else if indexPath.section == 1 {
            let vc = SelectionTableViewController(style: .Grouped)
            var names: [String] = []
            for mixer in mixerList { names.append(mixer.name) }
            vc.items = names
            vc.title = "Mixers"
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    // MARK: SelectionTableViewControllerDelegate
    
    func selectionTableWithTag(tag: Int, didSelectItem item: Int) {
        selectedMixerConfiguration = item
        mixerTypeLabel.text = mixerList[item].name
    }
    
    
    // MARK: IBActions
    
    @IBAction func save(sender: AnyObject) {
        dataStorage.mixerConfiguration = selectedMixerConfiguration
        dataStorage.boardAlignRoll = rollAdjustment.intValue
        dataStorage.boardAlignPitch = pitchAdjustment.intValue
        dataStorage.boardAlignYaw = yawAdjustment.intValue
        msp.crunchAndSendMSP(MSP_SET_BF_CONFIG)
        
        dataStorage.accTrimRoll = rollAccTrim.intValue
        dataStorage.accTrimPitch = pitchAccTrim.intValue
        msp.crunchAndSendMSP(MSP_SET_ACC_TRIM)
        
        dataStorage.loopTime = loopTime.intValue
        msp.crunchAndSendMSP(MSP_SET_LOOP_TIME)
        
        msp.sendMSP(MSP_EEPROM_WRITE)
        msp.sendMSP(MSP_SET_REBOOT) // Has to reboot only on this screen & the ports screen
    }

}
