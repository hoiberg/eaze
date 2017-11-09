//
//  GeneralConfigViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 23-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

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
    
    fileprivate let mspCodes = [MSP_BF_CONFIG, MSP_ACC_TRIM, MSP_LOOP_TIME, MSP_STATUS, MSP_BOARD_ALIGNMENT, MSP_MIXER]
    fileprivate var selectedMixerConfiguration = 2
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPhone ? .portrait : [.landscapeLeft, .landscapeRight]
    }
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addSubscriber(self, forCodes: mspCodes)
        
        // as the view is re-loaded every time it is shown, we don't have to send our requests in viewWillAppear
        if bluetoothSerial.isConnected {
            sendDataRequest()
            serialOpened()
        } else {
            serialClosed()
        }
        
        notificationCenter.addObserver(self, selector: #selector(serialOpened), name: Notification.Name.Serial.opened, object: nil)
        notificationCenter.addObserver(self, selector: #selector(serialClosed), name: Notification.Name.Serial.closed, object: nil)
        
        for field in [rollAdjustment, pitchAdjustment, yawAdjustment] {
            field?.maxValue = 360
            field?.minValue = -180
            field?.decimal = 0
            field?.increment = 1
            field?.suffix = "º"
        }
        
        for field in [rollAccTrim, pitchAccTrim] {
            field?.maxValue = 300
            field?.minValue = -300
            field?.decimal = 0
            field?.increment = 1
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
        var codes = mspCodes
        if dataStorage.apiVersion < "1.8.0" {
            codes.removeObject(MSP_LOOP_TIME)
        }
        
        if _bf_config_depreciated {
            codes.removeObject(MSP_BF_CONFIG)
        } else {
            codes.removeObjects([MSP_MIXER, MSP_BOARD_ALIGNMENT])
        }
        
        msp.sendMSP(codes)
    }
    
    func mspUpdated(_ code: Int) {
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
                calibrateMagLabel.isEnabled = true
            }
            
        case MSP_BOARD_ALIGNMENT:
            rollAdjustment.intValue = dataStorage.boardAlignRoll
            pitchAdjustment.intValue = dataStorage.boardAlignPitch
            yawAdjustment.intValue = dataStorage.boardAlignYaw

        case MSP_MIXER:
            selectedMixerConfiguration = dataStorage.mixerConfiguration
            mixerTypeLabel.text = mixerList[dataStorage.mixerConfiguration].name
            
        default:
            log(.Warn, "GeneralConfigViewController received MSP code not subscribed to: \(code)")
        }
    }
    
    
    // MARK: Serial events
    
    @objc func serialOpened() {
        if isBeingShown {
            sendDataRequest()
        }
        
        saveButton.isEnabled = true
        calibrateAccLabel.isEnabled = true
        calibrateMagLabel.isEnabled = false
        resetLabel.isEnabled = true
        
        if dataStorage.apiVersion >= "1.8.0" {
            loopTime.enabled = true
        } else {
            loopTime.enabled = false
        }
    }
    
    @objc func serialClosed() {
        saveButton.isEnabled = false
        calibrateAccLabel.isEnabled = false
        calibrateMagLabel.isEnabled = false
        resetLabel.isEnabled = false
    }
    
    
    // MARK: AdjustableTextFieldDelegate
    
    func staticAdjustableTextFieldChangedValue(_ field: StaticAdjustableTextField) {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                // calibrate acc
                let alert = UIAlertController(title: "Accelerometer Calibration",
                                            message: "Place board or frame on leveled surface, then tap 'Proceed'. Ensure platform is not moving during calibration",
                                     preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Proceed", style: .default) { _ in
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
                
                present(alert, animated: true, completion: nil)
                
            } else if indexPath.row == 1 {
                // calibrate mag
                guard dataStorage.activeSensors.bitCheck(2) else { return }
                
                let alert = UIAlertController(title: "Compass Calibration",
                                            message: "Move multirotor at least 360º on all axis of rotation, within 30 seconds",
                                     preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Proceed", style: .default) { _ in
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
                
                present(alert, animated: true, completion: nil)
                
            } else {
                // reset
                let alert = UIAlertController(title: "Restore settings to defaults",
                                            message: "All current configuration settings will be lost. Continue?",
                                     preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Proceed", style: .destructive) { _ in
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
                
                present(alert, animated: true, completion: nil)
            }
        } else if indexPath.section == 1 {
            let vc = SelectionTableViewController(style: .grouped)
            var names: [String] = []
            for mixer in mixerList { names.append(mixer.name) }
            vc.title = "Mixers"
            vc.items = names
            vc.selectedItem = selectedMixerConfiguration
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    // MARK: SelectionTableViewControllerDelegate
    
    func selectionTableWithTag(_ tag: Int, didSelectItem item: Int) {
        selectedMixerConfiguration = item
        mixerTypeLabel.text = mixerList[item].name
    }
    
    
    // MARK: IBActions
    
    @IBAction func save(_ sender: AnyObject) {
        var codes = [Int]()
        
        dataStorage.mixerConfiguration = selectedMixerConfiguration
        dataStorage.boardAlignRoll = rollAdjustment.intValue
        dataStorage.boardAlignPitch = pitchAdjustment.intValue
        dataStorage.boardAlignYaw = yawAdjustment.intValue
        if _bf_config_depreciated {
            codes += [MSP_SET_BOARD_ALIGNMENT, MSP_SET_MIXER]
        } else {
            codes.append(MSP_SET_BF_CONFIG)
        }

        dataStorage.accTrimRoll = rollAccTrim.intValue
        dataStorage.accTrimPitch = pitchAccTrim.intValue
        codes.append(MSP_SET_ACC_TRIM)
        
        if dataStorage.apiVersion >= "1.8.0" {
            dataStorage.loopTime = loopTime.intValue
            codes.append(MSP_SET_LOOP_TIME)
        }
        
        msp.crunchAndSendMSP(codes) {
            msp.sendMSP([MSP_EEPROM_WRITE, MSP_SET_REBOOT]) {
                delay(1, callback: self.sendDataRequest) // reload
            }
        }
    }
}
