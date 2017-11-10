//
//  HomeViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 04-04-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//
//  Idea for future update: "More Info" button on bottom. On tap: blurview moves up (à la yahoo weather) with
//  FC version info, and other stats. This would replace the info box. The more info button would have a light
//  40% alpha background.
//

import UIKit

final class HomeViewController: UIViewController, MSPUpdateSubscriber {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var efis: EFIS!
    @IBOutlet weak var infoBox: GlassBox!
    @IBOutlet var sensorLabels: [GlassLabel]!
    @IBOutlet weak var referenceModeLabel: GlassLabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var voltageIndicator: GlassIndicator!
    @IBOutlet weak var amperageIndicator: GlassIndicator!
    @IBOutlet weak var RSSIIndicator: GlassIndicator!
    @IBOutlet weak var BluetoothRSSIIndicator: GlassIndicator!
    @IBOutlet weak var bottomMarginConstraint: NSLayoutConstraint?
    
    
    // MARK: - Variables
    
    fileprivate var fastUpdateTimer: Timer?,
                slowUpdateTimer: Timer?,
                currentModes: [String] = [],
                modeLabels: [GlassLabel] = []
    
    fileprivate let mspCodes = [MSP_BOARD_INFO, MSP_FC_VARIANT, MSP_FC_VERSION, MSP_BUILD_INFO],
                fastMSPCodes = [MSP_ATTITUDE],
                slowMSPCodes = [MSP_STATUS, MSP_ANALOG]
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addSubscriber(self, forCodes: mspCodes + fastMSPCodes + slowMSPCodes)
        
        referenceModeLabel.isHidden = true
        
        connectButton.backgroundColor = UIColor.clear
        connectButton.setBackgroundColor(UIColor.black.withAlphaComponent(0.18), forState: UIControlState())
        connectButton.setBackgroundColor(UIColor.black.withAlphaComponent(0.08), forState: .highlighted)
        
        if UIDevice.isPhone && UIScreen.main.bounds.size.height < 568 {
            // 3.5" - use this constraint to place the bottom indicators a little lower
            bottomMarginConstraint?.constant = 6
        }

        
        notificationCenter.addObserver( self,
                              selector: #selector(serialOpened),
                                  name: Notification.Name.Serial.opened,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(serialClosed),
                                  name: Notification.Name.Serial.closed,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(serialWillAutoConnect),
                                  name: Notification.Name.Serial.willAutoConnect,
                                object: nil)
    
        notificationCenter.addObserver( self,
                              selector: #selector(serialDidFailToConnect),
                                  name: Notification.Name.Serial.didFailToConnect,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(serialDidDiscoverPeripheral),
                                  name: Notification.Name.Serial.didDiscoverNewPeripheral,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(serialDidStopScanning),
                                  name: Notification.Name.Serial.didStopScanning,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(serialDidUpdateState),
                                  name: Notification.Name.Serial.didUpdateState,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(willResignActive),
                                  name: Notification.Name.App.willResignActive,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(didBecomeActive),
                                  name: Notification.Name.App.didBecomeActive,
                                object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if bluetoothSerial.isConnected {
            serialOpened() // send request & schedule timer
        } else {
            serialClosed() // reset UI
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if bluetoothSerial.isConnected {
            fastUpdateTimer?.invalidate()
            slowUpdateTimer?.invalidate()
        } else if bluetoothSerial.isConnecting || bluetoothSerial.isReconnecting {
            bluetoothSerial.disconnect()
        } else if bluetoothSerial.isScanning {
            bluetoothSerial.stopScan()
        }
    }
    
    @objc func didBecomeActive() {
        guard isBeingShown else { return }
        if bluetoothSerial.isConnected {
            serialOpened()
        }
    }
    
    @objc func willResignActive() {
        guard isBeingShown else { return }
        if bluetoothSerial.isConnected {
            fastUpdateTimer?.invalidate()
            slowUpdateTimer?.invalidate()
        } else if bluetoothSerial.isConnecting {
            bluetoothSerial.disconnect()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    
    fileprivate func reloadModeLabels() {
        var x = referenceModeLabel.frame.maxX
        for mode in currentModes {
            let newLabel = GlassLabel(frame: referenceModeLabel.frame)
            newLabel.background = .green
            newLabel.text = mode
            newLabel.adjustToTextSize()
            newLabel.frame.origin.x = x - newLabel.frame.width
            
            view.addSubview(newLabel)
            modeLabels.append(newLabel)
            x = newLabel.frame.minX - 5
        }
    }
    
    
    // MARK: - Data request / update
    
    @objc func sendFastDataRequest() {
        msp.sendMSP(fastMSPCodes)
    }
    
    @objc func sendSlowDataRequest() {
        msp.sendMSP(slowMSPCodes)
        bluetoothSerial.readRSSI(rssiUpdated)
    }
    
    func rssiUpdated(_ RSSI: NSNumber) {
        BluetoothRSSIIndicator.text = "\(RSSI.intValue)"
        BluetoothRSSIIndicator.setIndication((RSSI.doubleValue+100.0)/60.0)
    }
    
    func mspUpdated(_ code: Int) {
        switch code {
        case MSP_ATTITUDE:
            efis.roll = dataStorage.attitude[0]
            efis.pitch = dataStorage.attitude[1]
            efis.heading = dataStorage.attitude[2]
            
        case MSP_BOARD_INFO:
            infoBox.firstUpperText = dataStorage.boardName
            infoBox.secondUpperText = dataStorage.boardVersion > 0 ? "version \(dataStorage.boardVersion)" : ""
            infoBox.reloadText()
            
        case MSP_FC_VARIANT, MSP_FC_VERSION:
            infoBox.firstLowerText = dataStorage.flightControllerName + " " + dataStorage.flightControllerVersion.stringValue
            infoBox.reloadText()
            
        case MSP_BUILD_INFO:
            infoBox.secondLowerText = dataStorage.buildInfo
            infoBox.reloadText()
            
        case MSP_STATUS:
            for label in sensorLabels {
                label.background = dataStorage.activeSensors.bitCheck(label.tag)  ? .dark : .red
            }
            
            if dataStorage.activeFlightModes != currentModes {
                // remove previous and add new
                currentModes = dataStorage.activeFlightModes
                modeLabels.forEach { $0.removeFromSuperview() }
                modeLabels = []
                
                let height = referenceModeLabel.frame.height,
                    y = referenceModeLabel.frame.minY
                var x = referenceModeLabel.frame.maxX
                
                for mode in currentModes {
                    let label = GlassLabel(frame: CGRect(x: 0, y: y, width: 0, height: height))
                    label.background = .green
                    label.text = mode
                    label.adjustToTextSize()
                    label.frame.origin.x = x - label.frame.width
                    x = label.frame.origin.x - 9 // add margin
                    
                    modeLabels.append(label)
                    view.addSubview(label)
                }
            }
            
        case MSP_ANALOG:
            voltageIndicator.text = "\(dataStorage.voltage.stringWithDecimals(1))V"
            amperageIndicator.text = "\(Int(round(dataStorage.amperage)))A"
            RSSIIndicator.text = "\(dataStorage.rssi)%"
            
            // Note: We don't set the voltage indicator, since voltage cannot be used
            // to get an accurate % charged of a battery (not while using it, at least)
            amperageIndicator.setIndication(dataStorage.amperage/50)
            RSSIIndicator.setIndication(Double(dataStorage.rssi)/100)

        default:
            log(.Warn, "Invalid MSP code update sent to HomeViewController: \(code)")
        }
    }
    
    
    // MARK: - Serial events
    
    @objc func serialOpened() {
        connectButton.setTitle("Disconnect", for: UIControlState())
        connectButton.setTitleColor(UIColor(hex: 0xFF8C8C), for: UIControlState())
        activityIndicator.stopAnimating()
        
        slowUpdateTimer?.invalidate()
        fastUpdateTimer?.invalidate()
        
        slowUpdateTimer = Timer.scheduledTimer( timeInterval: 0.6,
                                                                  target: self,
                                                                  selector: #selector(HomeViewController.sendSlowDataRequest),
                                                                  userInfo: nil,
                                                                  repeats: true)
        
        fastUpdateTimer = Timer.scheduledTimer( timeInterval: 0.15,
                                                                  target: self,
                                                                  selector: #selector(HomeViewController.sendFastDataRequest),
                                                                  userInfo: nil,
                                                                  repeats: true)
    }
    
    @objc func serialClosed() {
        connectButton.setTitle("Connect", for: UIControlState())
        connectButton.setTitleColor(UIColor.white, for: UIControlState())
        activityIndicator.stopAnimating()
        
        efis.roll = 0
        efis.pitch = 0
        efis.heading = 0
        
        infoBox.firstUpperText = ""
        infoBox.secondUpperText = ""
        infoBox.firstLowerText = ""
        infoBox.secondLowerText = ""
        infoBox.reloadText()
        
        voltageIndicator.text = "0.0V"
        amperageIndicator.text = "0A"
        RSSIIndicator.text = "0%"
        BluetoothRSSIIndicator.text = "0"
        
        voltageIndicator.setIndication(1.0)
        amperageIndicator.setIndication(1.0)
        RSSIIndicator.setIndication(1.0)
        BluetoothRSSIIndicator.setIndication(1.0)
        
        for label in sensorLabels {
            label.background = .dark
        }
        
        fastUpdateTimer?.invalidate()
        slowUpdateTimer?.invalidate()
    }
    
    @objc func serialWillAutoConnect() {
        connectButton.setTitle("Connecting", for: UIControlState())
        activityIndicator.startAnimating()
    }
    
    @objc func serialDidFailToConnect() {
        connectButton.setTitle("Connect", for: UIControlState())
        activityIndicator.stopAnimating()
    }
    
    @objc func serialDidDiscoverPeripheral(_ notification: Notification) {
        guard presentedViewController == nil && notification.userInfo!["WillAutoConnect"] as! Bool == false else { return }
        
        let bundle = Bundle.main,
            storyboard = UIStoryboard(name: "Uni", bundle: bundle),
            connectViewController = storyboard.instantiateViewController(withIdentifier: "ConnectViewController")
        
        present(connectViewController, animated: true, completion: nil)
    }
    
    @objc func serialDidStopScanning() {
        connectButton.setTitle("Connnect", for: UIControlState())
        activityIndicator.stopAnimating()
    }
    
    @objc func serialDidUpdateState() {
        if bluetoothSerial.state != .poweredOn {
            connectButton.setTitle("Connnect", for: UIControlState())
            activityIndicator.stopAnimating()
        }
    }
    
    
    // MARK: - IBActions
    
    @IBAction func connect(_ sender: AnyObject) {
        if bluetoothSerial.isConnected || bluetoothSerial.isReconnecting {
            bluetoothSerial.disconnect()

        } else if bluetoothSerial.isConnecting {
            connectButton.setTitle("Connect", for: UIControlState()) // we have to do this here because
            activityIndicator.stopAnimating() // serialClosed may not be called while connecting
            bluetoothSerial.disconnect()
            
        } else if bluetoothSerial.isScanning {
            bluetoothSerial.stopScan()
                    
        } else {
            if bluetoothSerial.state != .poweredOn {
                let alert = UIAlertController(title: "Bluetooth is disabled",
                                            message: nil,
                                     preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return
            }
            
            connectButton.setTitle("Scanning", for: UIControlState())
            activityIndicator.startAnimating()
            bluetoothSerial.startScan()
        }
    }
}
