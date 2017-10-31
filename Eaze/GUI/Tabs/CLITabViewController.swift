//
//  CLITabViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 27-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//
//  The only function of this viewController subclass is to enable/disable the 'Enter CLI mode' 

import UIKit

final class CLITabViewController: UIViewController {
    
    // MARK: - IBOutlets

    @IBOutlet weak var enterCLIButton: UIButton!
    @IBOutlet weak var bigLabel: UILabel!
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter.addObserver(self, selector: #selector(serialOpened), name: Notification.Name.Serial.opened, object: nil)
        notificationCenter.addObserver(self, selector: #selector(serialClosed), name: Notification.Name.Serial.closed, object: nil)
        
        if !bluetoothSerial.isConnected {
            enterCLIButton.isEnabled = false
        }
        
        if UIDevice.isPhone {
            bigLabel.text = "CLI Mode" // on iPad 'Command Line Interface'
        }
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    
    // MARK: - Serial events
    
    @objc func serialOpened() {
        enterCLIButton.isEnabled = true
    }
    
    @objc func serialClosed() {
        enterCLIButton.isEnabled = false
    }
    
    
    // MARK: - IBActions
    
    @IBAction func enterCLI(_ sender: AnyObject) {
        // load CLI async to speed up process
        MessageView.showProgressHUD("Loading CLI")
        DispatchQueue(label: "nl.hangar42.eaze.loadCLI").async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "CLIViewController")
            DispatchQueue.main.async {
                MessageView.hideProgressHUD()
                self.present(vc!, animated: true, completion: nil)
            }
        }
    }
}
