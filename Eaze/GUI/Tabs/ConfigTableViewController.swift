//
//  ConfigTableViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 22-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

final class ConfigTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    private let cellTitles  = [["General", "Receiver", "ESC/Motors", "Serial Ports", "Receiver Input"],
                               ["App Preferences", "Developer Console", "About This App"]],
                sectionTitles = ["Cleanflight", "App"],
                identifiers = [["General", "Receiver", "Motors", "Serial", "ReceiverInput"],
                               ["AppPrefs", "AppLog", "AboutApp"]]
    
    private var isLoading = false
    
    
    // MARK: - Functions
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return identifiers.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return identifiers[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.textLabel?.text = cellTitles[indexPath.section][indexPath.row]
        cell.imageView?.image = UIImage(named: "Config-" + identifiers[indexPath.section][indexPath.row])
        cell.imageView?.layer.cornerRadius = 6.0
        cell.imageView?.clipsToBounds = true
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard !isLoading else { return }
        isLoading = true
        
        // load vc async for better performance
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifiers[indexPath.section][indexPath.row])
            
            dispatch_async(dispatch_get_main_queue()) {
                self.isLoading = false
                if let split = self.splitViewController {
                    split.viewControllers[1] = UINavigationController(rootViewController: vc)
                } else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
}