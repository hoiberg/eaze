//
//  ReceiverInputViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 10-12-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

//TODO: Uit testen met ontvanger

import UIKit

final class ReceiverInputViewController: GroupedTableViewController, MSPUpdateSubscriber, StaticAdjustableTextFieldDelegate {
    
    // MARK: - Interface vars
    
    var refreshRateField: StaticAdjustableTextField?,
        nameLabels = [UILabel?](count: 32, repeatedValue: nil),
        labels = [UILabel?](count: 32, repeatedValue: nil),
        bars = [UIProgressView?](count: 32, repeatedValue: nil)

    
    // MARK: - Variables
    
    let mspCodes = [MSP_RX_MAP, MSP_RC]
    var channelNames = [String](count: 32, repeatedValue: ""),
        updateTimer: NSTimer?,
        isFirstTimeMSP_RC = true
    
    var updateInterval: Double {
        get {
            if let field = refreshRateField {
                return 1.0 / field.doubleValue
            } else {
                return 1.0 / 10.0 // default value
            }
        }
    }
    
    
    // MARK: - Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        msp.addSubscriber(self, forCodes: mspCodes)
        if bluetoothSerial.isConnected {
            sendDataRequest()
        }
        
        notificationCenter.addObserver(self, selector: #selector(ReceiverInputViewController.serialOpened), name: SerialOpenedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ReceiverInputViewController.serialClosed), name: SerialClosedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ReceiverInputViewController.didBecomeActive), name: AppDidBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ReceiverInputViewController.willResignActive), name: AppWillResignActiveNotification, object: nil)

        // populate channelNames
        channelNames[0...3] = ["Roll", "Pitch", "Yaw", "Throttle"]
        for i in 1 ... 32-4 {
            channelNames[i+3] = "AUX\(i)"
        }
        
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if bluetoothSerial.isConnected {
            scheduleUpdateTimer()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()
    }
    
    func didBecomeActive() {
        if isBeingShown && bluetoothSerial.isConnected {
            scheduleUpdateTimer()
        }
    }
    
    func willResignActive() {
        updateTimer?.invalidate()
    }
    
    private func scheduleUpdateTimer() {
        updateTimer?.invalidate() // always invalidate before (re-)scheduling, to prevent multiple timers running at the same time.
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: #selector(ReceiverInputViewController.updateRC), userInfo: nil, repeats: true)
    }
    
    
    // MARK: Data request / update
    
    func sendDataRequest() {
        msp.sendMSP(mspCodes)
    }
    
    func updateRC() {
        msp.sendMSP(MSP_RC)
    }
    
    func mspUpdated(code: Int) {
        switch code {
        case MSP_RX_MAP:
            let names = ["Roll", "Pitch", "Yaw", "Throttle", "AUX1", "AUX2", "AUX3", "AUX4"]
            for i in 0 ..< dataStorage.RC_MAP.count {
                channelNames[i] = names[dataStorage.RC_MAP.indexOf(i)!]
                nameLabels[i]?.text = channelNames[i]
            }

        case MSP_RC:
            for (index, chan) in dataStorage.channels.enumerate() {
                bars[index]?.progress = Float(chan) / 3000.0 // convert to 0.0-1.0 scale
                labels[index]?.text = "\(chan)"
            }
            if isFirstTimeMSP_RC {
                tableView.reloadData() // to get right amount of channel cells
                isFirstTimeMSP_RC = false
            }
            
        default:
            log(.Warn, "ReceiverInputViewController received MSP code not subscribed to: \(code)")
        }
    }
    
    
    // MARK: Serial events
    
    func serialOpened() {
        isFirstTimeMSP_RC = true
        sendDataRequest()
        
        // start timer if the view is being shown
        if isBeingShown {
            scheduleUpdateTimer()
        }
    }
    
    func serialClosed() {
        updateTimer?.invalidate()
    }
    
    
    // MARK: - AdjustableTextField
    
    func staticAdjustableTextFieldChangedValue(field: StaticAdjustableTextField) {
        if bluetoothSerial.isConnected {
            scheduleUpdateTimer()
        }
    }

    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : dataStorage.activeChannels
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("RefreshRateCell", forIndexPath: indexPath)
            refreshRateField = cell.viewWithTag(1) as! StaticAdjustableTextField?
            refreshRateField!.delegate = self
            refreshRateField!.intValue = 10
            refreshRateField!.maxValue = 30
            refreshRateField!.minValue = 1
            refreshRateField!.decimal = 0
            refreshRateField!.increment = 1
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("ChannelCell", forIndexPath: indexPath),
                nameLabel = cell.viewWithTag(1) as! UILabel,
                bar = cell.viewWithTag(2) as! UIProgressView,
                label = cell.viewWithTag(3) as! UILabel
            
            nameLabel.text = channelNames[indexPath.row]
            bar.progress = 3000.0 / Float(dataStorage.channels[indexPath.row])
            label.text = "\(dataStorage.channels[indexPath.row])"
            
            nameLabels[indexPath.row] = nameLabel
            bars[indexPath.row] = bar
            labels[indexPath.row] = label
            
            return cell
        }
    }
}