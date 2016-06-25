//
//  PIDSnapshotTableViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 14-10-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

class TuningSnapshotTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var addSnapshotButton: UIBarButtonItem!
    
    
    // MARK: - Variables
    
    var snapshots: [TuningSnapshot] = []

    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        snapshots = TuningSnapshot.loadAllSnapshots()
        if !bluetoothSerial.isConnected {
            addSnapshotButton.enabled = false
        }
    }

    
    // MARK: - TableView

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return snapshots.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SnapshotCell", forIndexPath: indexPath)
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd/MM/yy"

        cell.textLabel!.text = snapshots[indexPath.row].name
        cell.detailTextLabel!.text = formatter.stringFromDate(snapshots[indexPath.row].date)
        
        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            TuningSnapshot.deleteSnapshot(snapshots[indexPath.row])
            snapshots.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // pass on the snapshot to the detail view
        let vc = segue.destinationViewController as! TuningSnapshotDetailTableViewController
        vc.snapshot = snapshots[tableView.indexPathForSelectedRow!.row]
    }
    
    
    // MARK: - IBActions
    
    @IBAction func done(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func addBackup(sender: AnyObject) {
        let alert = UIAlertController(title: "Create Tuning Snapshot",
                                    message: "This will create a new tuning snaphot of the data that is currently on the flight controller. Please enter a name:",
                             preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        let backupAction = UIAlertAction(title: "Create snapshot", style: .Default) { (_) in
            let nameField = alert.textFields![0] as UITextField
            let newSnapshot = TuningSnapshot(name: nameField.text!)
            self.snapshots.insert(newSnapshot, atIndex: 0)
            self.tableView.reloadData()
        }
        
        backupAction.enabled = false
        
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Name for the snapshot"
            notificationCenter.addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                backupAction.enabled = textField.text != "" // make sure the textfield is not left empty
            }
        }
        
        alert.addAction(backupAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
}