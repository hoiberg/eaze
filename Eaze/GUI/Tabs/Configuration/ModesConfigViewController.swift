//
//  ModesConfigViewController.swift
//  Eaze
//
//  Created by Alex on 08-08-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

class ModesConfigViewController: GroupedTableViewController, MSPUpdateSubscriber {
    
    // MARK: - Interface vars
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var rangeCells: [ModeRangeTableViewCell?] = []
    
    
    // MARK: - Variables
    
    let mspCodes = [MSP_MODE_RANGE],
        sampleModeNames = ["ARM", "ANGLE", "HORIZON", "BARO", "MAG", "HEADFREE", "BEEPER", "AIRMODE"],
        sampleModeIDs = [0, 1, 2, 3, 5, 6, 13, 28]
    var modeRanges: [ModeRange] = [], // our local deep copy of dataStorage's array
        updateTimer: Timer?

    
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
        
        tableView.register(UINib(nibName: "ModeRangeTableViewCell", bundle: nil), forCellReuseIdentifier: "ModeRangeCell")
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
        updateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ModesConfigViewController.updateRC), userInfo: nil, repeats: true)
    }
    
    @objc func addButtonPressed(_ sender: UIButton) {
        let point = sender.convert(CGPoint.zero, to: tableView),
            section = tableView.indexPathForRow(at: point)!.section,
            identifier = bluetoothSerial.isConnected ? dataStorage.auxConfigIDs[section] : sampleModeIDs[section]
        modeRanges.append(ModeRange(id: identifier))
        
        if UIDevice.isPad {
            tableView.reloadData()
        } else {
            let path = IndexPath(row: tableView.numberOfRows(inSection: section), section: section)
            tableView.insertRows(at: [path], with: .fade)
        }
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
        case MSP_MODE_RANGE:
            modeRanges = dataStorage.modeRanges.deepCopy()
            for i in (0 ..< modeRanges.count).reversed() {
                if modeRanges[i].range.start >= modeRanges[i].range.end {
                    modeRanges.remove(at: i) // invalid
                }
            }
            tableView.reloadData()
            
        default:
            log(.Warn, "ModesConfigViewController received MSP code not subscribed to: \(code)")
        }
    }
    
    
    // MARK: Serial events
    
    @objc func serialOpened() {
        if isBeingShown {
            sendDataRequest()
            scheduleUpdateTimer()
        }
        
        saveButton.isEnabled = true
    }
    
    @objc func serialClosed() {
        updateTimer?.invalidate()
        saveButton.isEnabled = false
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (bluetoothSerial.isConnected ? dataStorage.auxConfigNames : sampleModeNames).count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let identifier = bluetoothSerial.isConnected ? dataStorage.auxConfigIDs[section] : sampleModeIDs[section],
            relevantRanges = modeRanges.filter({ $0.identifier == identifier })
        return 1 + relevantRanges.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath),
                label = cell.viewWithTag(1) as! UILabel,
                button = cell.viewWithTag(2) as! UIButton
            
            label.text = (bluetoothSerial.isConnected ? dataStorage.auxConfigNames : sampleModeNames)[indexPath.section]
            button.addTarget(self, action: #selector(ModesConfigViewController.addButtonPressed(_:)), for: .touchUpInside)
            
            if UIDevice.isPhone {
                cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.size.width, bottom: 0, right: 0)
            }
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ModeRangeCell", for: indexPath) as! ModeRangeTableViewCell
            
            let range = modeRanges.filter({ $0.identifier == (bluetoothSerial.isConnected ? dataStorage.auxConfigIDs : sampleModeIDs)[indexPath.section]})[indexPath.row - 1]
            cell.modeRange = range
            
            let index = modeRanges.index{$0 === range}!
            while rangeCells.count-1 < index { rangeCells.append(nil) }
            rangeCells[index] = cell // same order as modeRanges
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row == 0 || !tableView.isEditing ? false : true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return tableView.isEditing ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ModeRangeTableViewCell
        rangeCells.remove(at: rangeCells.index{$0===cell}!)
        modeRanges.remove(at: modeRanges.index{$0===cell.modeRange}!)
        
        if UIDevice.isPad {
            tableView.reloadData()
        } else {
            tableView.deleteRows(at: [indexPath], with: .right)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 31 : 55
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 31 : 55
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        if let rangeCell = cell as? ModeRangeTableViewCell {
            rangeCell.updateConstraints()
            rangeCell.reloadView()
            rangeCell.layoutSubviews()
            rangeCell.updateConstraints()
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func edit(_ sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.isEditing, animated: UIDevice.isPad ? false : true) // animated is glitchy on iPads/GroupedTableViewC, because of the constant constraints that are updated upon resize
        sender.title = tableView.isEditing ? "Done" : "Edit"
        sender.style = tableView.isEditing ? UIBarButtonItemStyle.done : UIBarButtonItemStyle.plain
    }
    
    @IBAction func save(_ sender: AnyObject) {
        let required = dataStorage.modeRanges.count
        dataStorage.modeRanges = modeRanges.deepCopy()
        
        while dataStorage.modeRanges.count < required {
            let range = ModeRange(id: 0)
            range.auxChannelIndex = 0
            range.range = (900, 900)
            dataStorage.modeRanges.append(range)
        }
        
        msp.sendModeRanges {
            msp.sendMSP(MSP_EEPROM_WRITE, callback: self.sendDataRequest)
        }
    }
}
