//
//  ReceiverInputViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 10-12-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

final class ReceiverInputViewController: GroupedTableViewController, MSPUpdateSubscriber, StaticAdjustableTextFieldDelegate {
    
    // MARK: - Interface vars
    
    var nameLabels = [UILabel?](count: 32, repeatedValue: nil),
        labels = [UILabel?](count: 32, repeatedValue: nil),
        bars = [UIProgressView?](count: 32, repeatedValue: nil)

    
    // MARK: - Variables
    
    let mspCodes = [MSP_RX_MAP, MSP_RC],
        refNames = ["Roll", "Pitch", "Yaw", "Throttle", "AUX1", "AUX2", "AUX3", "AUX4"]
    
    var channelNames = [String](count: 32, repeatedValue: ""),
        updateTimer: NSTimer?,
        isFirstTimeMSP_RC = true
    
    
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

    deinit {
        notificationCenter.removeObserver(self)
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
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: #selector(ReceiverInputViewController.updateRC), userInfo: nil, repeats: true)
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
            for i in 0 ..< dataStorage.RC_MAP.count {
                channelNames[i] = refNames[dataStorage.RC_MAP.indexOf(i)!]
                nameLabels[i]?.text = channelNames[i]
            }

        case MSP_RC:
            for (index, chan) in dataStorage.channels.enumerate() {
                let realIndex = dataStorage.RC_MAP[safe: index] ?? index
                bars[realIndex]?.progress = (Float(chan) - 500.0) / 2000.0 // convert to 0.0-1.0 scale
                labels[realIndex]?.text = "\(chan)"
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
        
        // start timer if the view is being shown
        if isBeingShown {
            sendDataRequest()
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
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetoothSerial.isConnected ? dataStorage.activeChannels : 8 // load sample data if not connected
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChannelCell", forIndexPath: indexPath),
            nameLabel = cell.viewWithTag(1) as! UILabel,
            barSuperView = cell.viewWithTag(2)!,
            bar = barSuperView.viewWithTag(1) as! UIProgressView,
            label = cell.viewWithTag(3) as! UILabel
        
        barSuperView.layer.cornerRadius = 3
        barSuperView.layer.masksToBounds = true
        bar.transform = CGAffineTransformMakeScale(1, 7)
        
        if bluetoothSerial.isConnected {
            nameLabel.text = channelNames[safe: indexPath.row] ?? "ERR"
            bar.progress = Float(dataStorage.channels[safe: indexPath.row] ?? 0.0) / 3000.0 // convert to 0.0-1.0 scale
            label.text = "\(dataStorage.channels[safe: indexPath.row] ?? 0)"
        } else {
            nameLabel.text = refNames[indexPath.row]
            bar.progress = 0.5
            label.text = "1500"
        }
        
        nameLabels[indexPath.row] = nameLabel
        bars[indexPath.row] = bar
        labels[indexPath.row] = label
        
        return cell
    }
}