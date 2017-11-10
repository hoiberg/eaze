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
            addSnapshotButton.isEnabled = false
        }
    }

    
    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return snapshots.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SnapshotCell", for: indexPath)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"

        cell.textLabel!.text = snapshots[indexPath.row].name
        cell.detailTextLabel!.text = formatter.string(from: snapshots[indexPath.row].date as Date)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            TuningSnapshot.deleteSnapshot(snapshots[indexPath.row])
            snapshots.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // pass on the snapshot to the detail view
        let vc = segue.destination as! TuningSnapshotDetailTableViewController
        vc.snapshot = snapshots[tableView.indexPathForSelectedRow!.row]
    }
    
    
    // MARK: - IBActions
    
    @IBAction func done(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addBackup(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Create Tuning Snapshot",
                                    message: "This will create a new tuning snaphot of the data that is currently on the flight controller. Please enter a name:",
                             preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        let backupAction = UIAlertAction(title: "Create snapshot", style: .default) { (_) in
            let nameField = alert.textFields![0] as UITextField
            let newSnapshot = TuningSnapshot(name: nameField.text!)
            self.snapshots.insert(newSnapshot, at: 0)
            self.tableView.reloadData()
        }
        
        backupAction.isEnabled = false
        
        alert.addTextField { (textField) in
            textField.placeholder = "Name for the snapshot"
            textField.autocapitalizationType = .words
            notificationCenter.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                backupAction.isEnabled = textField.text != "" // make sure the textfield is not left empty
            }
        }
        
        alert.addAction(backupAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}
