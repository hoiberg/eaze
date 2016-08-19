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
        updateTimer: NSTimer?
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        msp.addSubscriber(self, forCodes: mspCodes)
        if bluetoothSerial.isConnected {
            serialOpened()
        } else {
            serialClosed()
        }
        
        notificationCenter.addObserver(self, selector: #selector(ModesConfigViewController.serialOpened), name: SerialOpenedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ModesConfigViewController.serialClosed), name: SerialClosedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ModesConfigViewController.didBecomeActive), name: AppDidBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ModesConfigViewController.willResignActive), name: AppWillResignActiveNotification, object: nil)
        
        tableView.registerNib(UINib(nibName: "ModeRangeTableViewCell", bundle: nil), forCellReuseIdentifier: "ModeRangeCell")
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
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(ReceiverInputViewController.updateRC), userInfo: nil, repeats: true)
    }
    
    func addButtonPressed(sender: UIButton) {
        let point = sender.convertPoint(CGPointZero, toView: tableView),
            section = tableView.indexPathForRowAtPoint(point)!.section,
            identifier = bluetoothSerial.isConnected ? dataStorage.auxConfigIDs[section] : sampleModeIDs[section]
        modeRanges.append(ModeRange(id: identifier))
        
        if UIDevice.isPad {
            tableView.reloadData()
        } else {
            let path = NSIndexPath(forRow: tableView.numberOfRowsInSection(section), inSection: section)
            tableView.insertRowsAtIndexPaths([path], withRowAnimation: .Fade)
        }
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
        case MSP_MODE_RANGE:
            modeRanges = dataStorage.modeRanges.deepCopy()
            for i in (0 ..< modeRanges.count).reverse() {
                if modeRanges[i].range.start >= modeRanges[i].range.end {
                    modeRanges.removeAtIndex(i) // invalid
                }
            }
            tableView.reloadData()
            
        default:
            log(.Warn, "ModesConfigViewController received MSP code not subscribed to: \(code)")
        }
    }
    
    
    // MARK: Serial events
    
    func serialOpened() {
        sendDataRequest()
        
        saveButton.enabled = true
        
        // start timer if the view is being shown
        if isBeingShown {
            scheduleUpdateTimer()
        }
    }
    
    func serialClosed() {
        updateTimer?.invalidate()
        saveButton.enabled = false
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (bluetoothSerial.isConnected ? dataStorage.auxConfigNames : sampleModeNames).count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let identifier = bluetoothSerial.isConnected ? dataStorage.auxConfigIDs[section] : sampleModeIDs[section],
            relevantRanges = modeRanges.filter({ $0.identifier == identifier })
        return 1 + relevantRanges.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("HeaderCell", forIndexPath: indexPath),
                label = cell.viewWithTag(1) as! UILabel,
                button = cell.viewWithTag(2) as! UIButton
            
            label.text = (bluetoothSerial.isConnected ? dataStorage.auxConfigNames : sampleModeNames)[indexPath.section]
            button.addTarget(self, action: #selector(ModesConfigViewController.addButtonPressed(_:)), forControlEvents: .TouchUpInside)
            
            if UIDevice.isPhone {
                cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.size.width, bottom: 0, right: 0)
            }
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("ModeRangeCell", forIndexPath: indexPath) as! ModeRangeTableViewCell
            
            let range = modeRanges.filter({ $0.identifier == (bluetoothSerial.isConnected ? dataStorage.auxConfigIDs : sampleModeIDs)[indexPath.section]})[indexPath.row - 1]
            cell.modeRange = range
            
            let index = modeRanges.indexOf{$0 === range}!
            while rangeCells.count-1 < index { rangeCells.append(nil) }
            rangeCells[index] = cell // same order as modeRanges
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row == 0 || !tableView.editing ? false : true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return tableView.editing ? .Delete : .None
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! ModeRangeTableViewCell
        rangeCells.removeAtIndex(rangeCells.indexOf{$0===cell}!)
        modeRanges.removeAtIndex(modeRanges.indexOf{$0===cell.modeRange}!)
        
        if UIDevice.isPad {
            tableView.reloadData()
        } else {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.row == 0 ? 31 : 55
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.row == 0 ? 31 : 55
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
        if let rangeCell = cell as? ModeRangeTableViewCell {
            rangeCell.updateConstraints()
            rangeCell.reloadView()
            rangeCell.layoutSubviews()
            rangeCell.updateConstraints()
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func edit(sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.editing, animated: UIDevice.isPad ? false : true) // animated is glitchy on iPads/GroupedTableViewC, because of the constant constraints that are updated upon resize
        sender.title = tableView.editing ? "Done" : "Edit"
        sender.style = tableView.editing ? UIBarButtonItemStyle.Done : UIBarButtonItemStyle.Plain
    }
    
    @IBAction func save(sender: AnyObject) {
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