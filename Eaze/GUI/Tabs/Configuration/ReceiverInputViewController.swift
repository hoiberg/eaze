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
    
    var nameLabels = [UILabel?](repeating: nil, count: 32),
        labels = [UILabel?](repeating: nil, count: 32),
        bars = [UIProgressView?](repeating: nil, count: 32)

    
    // MARK: - Variables
    
    let mspCodes = [MSP_RX_MAP, MSP_RC],
        refNames = ["Roll", "Pitch", "Yaw", "Throttle", "AUX1", "AUX2", "AUX3", "AUX4"]
    
    var channelNames = [String](repeating: "", count: 32),
        updateTimer: Timer?,
        isFirstTimeMSP_RC = true
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPhone ? .portrait : [.landscapeLeft, .landscapeRight]
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
        notificationCenter.addObserver(self, selector: #selector(didBecomeActive), name: Notification.Name.App.didBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(willResignActive), name: Notification.Name.App.willResignActive, object: nil)

        // populate channelNames
        channelNames[0...3] = ["Roll", "Pitch", "Yaw", "Throttle"]
        for i in 1 ... 32-4 {
            channelNames[i+3] = "AUX\(i)"
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if bluetoothSerial.isConnected {
            scheduleUpdateTimer()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
    
    
    @objc func didBecomeActive() {
        if isBeingShown && bluetoothSerial.isConnected {
            scheduleUpdateTimer()
        }
    }
    
    @objc func willResignActive() {
        updateTimer?.invalidate()
    }
    
    fileprivate func scheduleUpdateTimer() {
        updateTimer?.invalidate() // always invalidate before (re-)scheduling, to prevent multiple timers running at the same time.
        updateTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(ReceiverInputViewController.updateRC), userInfo: nil, repeats: true)
    }
    
    
    // MARK: Data request / update
    
    func sendDataRequest() {
        msp.sendMSP(mspCodes)
    }
    
    @objc func updateRC() {
        msp.sendMSP(MSP_RC)
    }
    
    func mspUpdated(_ code: Int) {
        switch code {
        case MSP_RX_MAP:
            for i in 0 ..< dataStorage.RC_MAP.count {
                channelNames[i] = refNames[dataStorage.RC_MAP.index(of: i)!]
                nameLabels[i]?.text = channelNames[i]
            }

        case MSP_RC:
            for (index, chan) in dataStorage.channels.enumerated() {
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
    
    @objc func serialOpened() {
        isFirstTimeMSP_RC = true
        
        // start timer if the view is being shown
        if isBeingShown {
            sendDataRequest()
            scheduleUpdateTimer()
        }
    }
    
    @objc func serialClosed() {
        updateTimer?.invalidate()
    }
    
    
    // MARK: - AdjustableTextField
    
    func staticAdjustableTextFieldChangedValue(_ field: StaticAdjustableTextField) {
        if bluetoothSerial.isConnected {
            scheduleUpdateTimer()
        }
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetoothSerial.isConnected ? dataStorage.activeChannels : 8 // load sample data if not connected
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath),
            nameLabel = cell.viewWithTag(1) as! UILabel,
            barSuperView = cell.viewWithTag(2)!,
            bar = barSuperView.viewWithTag(1) as! UIProgressView,
            label = cell.viewWithTag(3) as! UILabel
        
        barSuperView.layer.cornerRadius = 3
        barSuperView.layer.masksToBounds = true
        bar.transform = CGAffineTransform(scaleX: 1, y: 7)
        
        if bluetoothSerial.isConnected {
            nameLabel.text = channelNames[safe: indexPath.row] ?? "ERR"
            bar.progress = Float(dataStorage.channels[safe: indexPath.row] ?? 0) / 3000.0 // convert to 0.0-1.0 scale
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
