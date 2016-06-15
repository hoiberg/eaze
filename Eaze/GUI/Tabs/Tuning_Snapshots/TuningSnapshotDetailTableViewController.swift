//
//  PIDSnapshotDetailTableViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 14-10-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//
//  I realized too late that using a dynamic tableview is not the best way to do this..
//  It has become a rather.... lets just say 'interesting' way to do something as basic as presenting some textfields..
//  But I'm too lazy to change this.
//  Yeah I know.. I know..

import UIKit

class TuningSnapshotDetailTableViewController: GroupedTableViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var writeButton: UIBarButtonItem!
    
    
    // MARK: - Variables 
    
    /// The selected tuning snapshot
    var snapshot: TuningSnapshot!
    
    /// Used to store uitableviewcells, to prevent reusing
    private var cells: [[UITableViewCell?]] = [[nil, nil, nil], [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil], [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]]

    
    // MARK: - Functions 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !bluetoothSerial.isConnected {
            writeButton.enabled = false
        }
        
        // load all cells, else the save method won't work
        for (i, arrr) in cells.enumerate() {
            for (j, _) in arrr.enumerate() {
                self.tableView(tableView, cellForRowAtIndexPath: NSIndexPath(forRow: j, inSection: i))
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        saveSnapshot() // auto save
    }
    
    func saveSnapshot() {
        
        func valueOfTextfield(tag: Int, inSection section: Int, atRow row: Int) -> String {
            let cell = cells[section][row]
            return (cell!.viewWithTag(tag) as! UITextField).text!
        }
        
        snapshot.name = valueOfTextfield(2, inSection: 0, atRow: 0)
        snapshot.PIDController = valueOfTextfield(2, inSection: 0, atRow: 2).intValue
        
        for i in 0...9 {
            snapshot.PIDs[i][0] = valueOfTextfield(2, inSection: 1, atRow: i).doubleValue
            snapshot.PIDs[i][1] = valueOfTextfield(3, inSection: 1, atRow: i).doubleValue
            snapshot.PIDs[i][2] = valueOfTextfield(4, inSection: 1, atRow: i).doubleValue
        }
        
        snapshot.rcRate              = valueOfTextfield(2, inSection: 2, atRow: 0).doubleValue
        snapshot.rcExpo              = valueOfTextfield(2, inSection: 2, atRow: 1).doubleValue
        snapshot.throttleMid         = valueOfTextfield(2, inSection: 2, atRow: 2).doubleValue
        snapshot.throttleExpo        = valueOfTextfield(2, inSection: 2, atRow: 3).doubleValue
        snapshot.rollRate            = valueOfTextfield(2, inSection: 2, atRow: 4).doubleValue
        snapshot.pitchRate           = valueOfTextfield(2, inSection: 2, atRow: 5).doubleValue
        snapshot.yawRate             = valueOfTextfield(2, inSection: 2, atRow: 6).doubleValue
        snapshot.yawExpo             = valueOfTextfield(2, inSection: 2, atRow: 7).doubleValue
        snapshot.dynamicThrottlePID  = valueOfTextfield(2, inSection: 2, atRow: 8).doubleValue
        snapshot.dynamicThrottleBreakpoint = valueOfTextfield(2, inSection: 2, atRow: 9).intValue
        
        snapshot.save()
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 10 // sections 1 and 2 have each 10 cells
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Main", "PID values", "Miscellaneous"][section]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Cell order is:
        // SECTION 1: Snapshot name; Date; PID controller
        // SECTION 2: All 30 PID values
        // SECTION 3: All 10 misc configuration values
        
        if let cell = cells[indexPath.section][indexPath.row] {
            return cell
        }
        
        var cell: UITableViewCell!
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                // name cell
                cell = NSBundle.mainBundle().loadNibNamed("NameFieldCell", owner: self, options: nil)[0] as! UITableViewCell
                (cell.viewWithTag(2) as! UITextField).text = snapshot.name
            } else if indexPath.row == 1 {
                // date cell
                cell = NSBundle.mainBundle().loadNibNamed("DateFieldCell", owner: self, options: nil)[0] as! UITableViewCell
                let formatter = NSDateFormatter()
                formatter.dateStyle = .MediumStyle
                (cell.viewWithTag(2) as! UILabel).text = formatter.stringFromDate(snapshot.date)
            } else {
                // pid controller cell
                cell = NSBundle.mainBundle().loadNibNamed("SingleFieldCell", owner: self, options: nil)[0] as! UITableViewCell
                (cell.viewWithTag(1) as! UILabel).text = "PID Controller"
                (cell.viewWithTag(2) as! UITextField).text = "\(snapshot.PIDController)"
            }
            
        } else if indexPath.section == 1 {
            // PIDs
            cell = NSBundle.mainBundle().loadNibNamed("TripleFieldCell", owner: self, options: nil)[0] as! UITableViewCell
            (cell.viewWithTag(1) as! UILabel).text = ["Roll", "Pitch", "Yaw", "Alt", "Pos", "PosR", "NavR", "Level", "Mag", "Level"][indexPath.row]
            (cell.viewWithTag(2) as! UITextField).text = snapshot.PIDs[indexPath.row][0].stringWithDecimals(3)
            (cell.viewWithTag(3) as! UITextField).text = snapshot.PIDs[indexPath.row][1].stringWithDecimals(3)
            (cell.viewWithTag(4) as! UITextField).text = snapshot.PIDs[indexPath.row][2].stringWithDecimals(3)
            
        } else {
            // misc data
            cell = NSBundle.mainBundle().loadNibNamed("SingleFieldCell", owner: self, options: nil)[0] as! UITableViewCell
            (cell.viewWithTag(1) as! UILabel).text = ["RC Rate", "RC Expo", "Throttle MID", "Throttle Expo", "Roll Rate", "Pitch Rate", "Yaw Rate", "Yaw Expo", "Throttle TPA", "Thr TPA Breakpoint"][indexPath.row]
            (cell.viewWithTag(2) as! UITextField).text = indexPath.row == 9 ? "\(snapshot.dynamicThrottleBreakpoint)" : (snapshot.valueForKeyPath(["rcRate", "rcExpo", "throttleMid", "throttleExpo", "rollRate", "pitchRate", "yawRate", "yawExpo", "dynamicThrottlePID", "dynamicThrottleBreakpoint"][indexPath.row]) as! Double).stringWithDecimals(2) // My entry for the bad coding pratices world championship :D I'm actually quite proud of this
        }
        
        cells[indexPath.section][indexPath.row] = cell
    
        return cell
    }
    
    
    // MARK - IBActions
    
    @IBAction func shareSnapshot(sender: AnyObject) {
        let activityViewController = UIActivityViewController(activityItems: [snapshot.fileURL!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        presentViewController(activityViewController, animated: true, completion: nil)
    }

    @IBAction func uploadSnapshot(sender: AnyObject) {
        let alert = UIAlertController(title: "Upload this snapshot to the Flight Controller?", message: "This will overwrite existing tuning settings, and you won't be able to undo this.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Upload", style: .Destructive, handler: {(_) -> Void in
            self.saveSnapshot() // save first
            if self.snapshot.PIDController > dataStorage.PIDControllerNames.count {
                let alert2 = UIAlertController(title: "PID Controller out of range", message: "Required range: 0-\(dataStorage.PIDControllerNames.count).", preferredStyle: .Alert)
                alert2.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                self.presentViewController(alert2, animated: true, completion: nil)
                return
            }
            self.snapshot.uploadToFlightController()
            notificationCenter.postNotificationName("ReloadTuningViewController", object: nil)
        }))
            
        presentViewController(alert, animated: true, completion: nil)
    }
    
}
