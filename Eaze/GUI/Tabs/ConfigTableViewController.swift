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
    
    fileprivate let cellTitles  = [["General", "Receiver", "ESC/Motors", "Serial Ports", "Modes", "Receiver Input"],
                               ["App Preferences", "Touch Controller", "Developer Console", "About This App"]],
                sectionTitles = ["Cleanflight", "App"],
                identifiers = [["General", "Receiver", "Motors", "Serial", "Modes", "ReceiverInput"],
                               ["AppPrefs", "ControllerInfo", "AppLog", "AboutApp"]]
    
    fileprivate var isLoading = false

    
    // MARK: - Functions
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return identifiers.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return identifiers[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = cellTitles[indexPath.section][indexPath.row]
        cell.imageView?.image = UIImage(named: "Config-" + identifiers[indexPath.section][indexPath.row])
        cell.imageView?.layer.cornerRadius = 6.0
        cell.imageView?.clipsToBounds = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard !isLoading else { return }
        isLoading = true
        
        // load vc async for better performance
        DispatchQueue(label: "nl.hangar42.eaze.loadConfig").async {
            let vc = self.storyboard!.instantiateViewController(withIdentifier: self.identifiers[indexPath.section][indexPath.row])
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let split = self.splitViewController {
                    split.viewControllers[1] = UINavigationController(rootViewController: vc)
                } else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
}
