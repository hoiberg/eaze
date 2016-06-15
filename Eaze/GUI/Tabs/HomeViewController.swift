//
//  HomeViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 04-04-16.
//  Copyright © 2016 Hangar42. All rights reserved.
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
    @IBOutlet weak var bottomMarginConstraint: NSLayoutConstraint!
    
    
    // MARK: - Variables
    
    private var fastUpdateTimer: NSTimer?,
                slowUpdateTimer: NSTimer?,
                previousModes: [String] = [],
                modeLabels: [GlassLabel] = []
    
    private let mspCodes = [MSP_BOARD_INFO, MSP_FC_VARIANT, MSP_FC_VERSION, MSP_BUILD_INFO],
                fastMSPCodes = [MSP_ATTITUDE],
                slowMSPCodes = [MSP_STATUS, MSP_ANALOG]
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msp.addSubscriber(self, forCodes: mspCodes)
        msp.addSubscriber(self, forCodes: fastMSPCodes)
        msp.addSubscriber(self, forCodes: slowMSPCodes)
        
        referenceModeLabel.hidden = true
        
        connectButton.backgroundColor = UIColor.clearColor()
        connectButton.setBackgroundColor(UIColor.blackColor().colorWithAlphaComponent(0.2), forState: .Normal)
        connectButton.setBackgroundColor(UIColor.whiteColor().colorWithAlphaComponent(0.08), forState: .Highlighted)
        
        if UIScreen.mainScreen().bounds.size.height < 568 {
            // 3.5" - use this constraint to place the bottom indicators a little lower
            bottomMarginConstraint.constant = 6
        }
        
        if UIScreen.mainScreen().bounds.size.height > 568 {
            // 4.7" and above - use this constraint to place graphs a bit farther apart
            bottomMarginConstraint.constant = 6
        }

        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialOpened),
                                  name: BluetoothSerialDidConnectNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialClosed),
                                  name: BluetoothSerialDidDisconnectNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialWillAutoConnect),
                                  name: BluetoothSerialWillAutoConnectNotification,
                                object: nil)
    
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialDidFailToConnect),
                                  name: BluetoothSerialDidFailToConnectNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialDidDiscoverPeripheral),
                                  name: BluetoothSerialDidDiscoverNewPeripheralNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.serialDidStopScanning),
                                  name: BluetoothSerialDidStopScanningNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.willResignActive),
                                  name: AppWillResignActiveNotification,
                                object: nil)
        
        notificationCenter.addObserver( self,
                              selector: #selector(HomeViewController.didBecomeActive),
                                  name: AppDidBecomeActiveNotification,
                                object: nil)

    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if bluetoothSerial.isConnected {
            begin()
        } else {
            stop()
        }
        
        // normally we'd call setup in the init of EFIS, but if we don't do this here,
        // the efis will get the wrong size on different screen sizes (since it does
        // not have any constraints that will resize all the subviews etc...)
        //efis.setup()

        print(view.bounds)
        print(efis.bounds)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if bluetoothSerial.isConnected {
            fastUpdateTimer?.invalidate()
            slowUpdateTimer?.invalidate()
        } else if bluetoothSerial.isConnecting {
            bluetoothSerial.disconnect()
        }
    }
    
    func didBecomeActive() {
        guard isBeingShown else { return }
        if bluetoothSerial.isConnected {
            begin()
        }
    }
    
    func willResignActive() {
        guard isBeingShown else { return }
        if bluetoothSerial.isConnected {
            fastUpdateTimer?.invalidate()
            slowUpdateTimer?.invalidate()
        } else if bluetoothSerial.isConnecting {
            bluetoothSerial.disconnect()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    private func reloadModeLabels() {
        var x = referenceModeLabel.frame.maxX
        for mode in previousModes {
            let newLabel = GlassLabel(frame: referenceModeLabel.frame)
            newLabel.background = .Green
            newLabel.text = mode
            newLabel.adjustToTextSize()
            newLabel.frame.origin.x = x - newLabel.frame.width
            
            view.addSubview(newLabel)
            modeLabels.append(newLabel)
            x = newLabel.frame.minX - 5
        }
    }
    
 /*   private func reloadStaticInfo() {
        //TODO: Not nice to do this both in mspupdated and here.. send the MSP commands anyway?? Or remove this??
        // infobox
        infoBox.firstUpperText = dataStorage.boardName
        infoBox.secondUpperText = dataStorage.boardVersion > 0 ? "version \(dataStorage.boardVersion)" : ""
        infoBox.firstLowerText = dataStorage.flightControllerName + " " + dataStorage.flightControllerVersion.stringValue
        infoBox.secondLowerText = dataStorage.buildInfo
        infoBox.reloadText()
        
        // active sensors
        for label in sensorLabels {
            label.background = dataStorage.activeSensors.bitCheck(label.tag)  ? .Dark : .Red
        }
    }*/
    
    
    // MARK: - Data request / update
    
    func begin() {
        connectButton.setTitle("Disconnect", forState: .Normal)
        connectButton.setTitleColor(UIColor(hex: 0xFF8C8C), forState: .Normal)
        activityIndicator.stopAnimating()
        
        //TODO: Test whether this can be removed
        //reloadStaticInfo()
        
        self.slowUpdateTimer = NSTimer.scheduledTimerWithTimeInterval( 1.0,
                                                               target: self,
                                                             selector: #selector(HomeViewController.sendSlowDataRequest),
                                                             userInfo: nil,
                                                              repeats: true)

        self.fastUpdateTimer = NSTimer.scheduledTimerWithTimeInterval( 0.1,
                                                               target: self,
                                                             selector: #selector(HomeViewController.sendFastDataRequest),
                                                             userInfo: nil,
                                                              repeats: true)
    }
    
    //TODO: Test whether this will be called in background
    func stop() {
        connectButton.setTitle("Connect", forState: .Normal)
        connectButton.setTitleColor(UIColor(hex: 0xFFFFFF /*0x98EE41*/), forState: .Normal)
        
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
            label.background = .Red
        }

        self.fastUpdateTimer?.invalidate()
        self.slowUpdateTimer?.invalidate()
    }
    
    func sendFastDataRequest() {
        msp.sendMSP(fastMSPCodes)
    }
    
    func sendSlowDataRequest() {
        msp.sendMSP(slowMSPCodes)
        bluetoothSerial.readRSSI(rssiUpdated)
    }
    
    func rssiUpdated(RSSI: NSNumber) {
        BluetoothRSSIIndicator.text = "\(RSSI.integerValue)"
        BluetoothRSSIIndicator.setIndication((RSSI.doubleValue+100.0)/60.0)
    }
    
    func mspUpdated(code: Int) {
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
            // active sensors
            for label in sensorLabels {
                label.background = dataStorage.activeSensors.bitCheck(label.tag)  ? .Dark : .Red
            }
            
            // active flight modes
            if dataStorage.activeFlightModes != previousModes {
                previousModes = dataStorage.activeFlightModes
                modeLabels.forEach { $0.removeFromSuperview() }
                modeLabels = []
            }
            
        case MSP_ANALOG:
            voltageIndicator.text = "\(dataStorage.voltage.stringWithDecimals(1))V"
            amperageIndicator.text = "\(dataStorage.amperage)A"
            RSSIIndicator.text = "\(dataStorage.rssi)%"
            
            // Note: We don't set the voltage indicator, since voltage cannot be used
            // to get an accurate % charged of a battery (not while using it, at least)
            amperageIndicator.setIndication(dataStorage.amperage/50)
            RSSIIndicator.setIndication(Double(dataStorage.rssi)/100)

        default:
            print("Invalid MSP code update sent to HomeViewController")
        }
    }
    
    
    // MARK: - Serial events
    
    func serialOpened() {
        begin()
    }
    
    func serialClosed() {
        stop()
    }
    
    func serialWillAutoConnect() {
        connectButton.setTitle("Connecting", forState: .Normal)
        activityIndicator.startAnimating()
    }
    
    func serialDidFailToConnect() {
        connectButton.setTitle("Connect", forState: .Normal)
        activityIndicator.stopAnimating()
    }
    
    func serialDidDiscoverPeripheral(notification: NSNotification) {
        guard presentedViewController == nil && notification.userInfo!["WillAutoConnect"] as! Bool == false else { return }
        
        let bundle = NSBundle.mainBundle(),
            storyboard = UIStoryboard(name: "Uni", bundle: bundle),
            connectViewController = storyboard.instantiateViewControllerWithIdentifier("ConnectViewController")
        
        presentViewController(connectViewController, animated: true, completion: nil)
    }
    
    func serialDidStopScanning() {
        //guard !bluetoothSerial.isConnecting else { return }
        connectButton.setTitle("Connnect", forState: .Normal)
        activityIndicator.stopAnimating()
    }
    
    
    // MARK: - IBActions
    
    @IBAction func connect(sender: AnyObject) {
        log("CONNECT")
        if bluetoothSerial.isConnected {
            bluetoothSerial.disconnect()

        } else if bluetoothSerial.isConnecting {
            connectButton.setTitle("Connect", forState: .Normal) // we have to do this here because
            activityIndicator.stopAnimating() // serialClosed may not be called while connecting
            bluetoothSerial.disconnect()
            
        } else if bluetoothSerial.isScanning {
            bluetoothSerial.stopScan()
        
        } else {
            if bluetoothSerial.state != .PoweredOn {
                let alert = UIAlertController(title: "Bluetooth not on",
                                              message: "Please turn Bluetooth on before trying to connect",
                                              preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            connectButton.setTitle("Scanning", forState: .Normal)
            activityIndicator.startAnimating()
            bluetoothSerial.startScan()
        }
    }
}