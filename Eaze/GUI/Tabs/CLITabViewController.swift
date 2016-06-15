//
//  CLITabViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 27-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//
//  The only function of this viewController subclass is to enable/disable the 'Enter CLI mode' 

import UIKit

class CLITabViewController: UIViewController {

    @IBOutlet weak var enterCLIButton: CleanButton!
    @IBOutlet weak var bigLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter.addObserver(self, selector: #selector(CLITabViewController.serialOpened), name: SerialOpenedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(CLITabViewController.serialClosed), name: SerialClosedNotification, object: nil)
        
        if !bluetoothSerial.isConnected {
            enterCLIButton.enabled = false
        }
        
        
        if UIDevice.isPhone {
            bigLabel.text = "CLI Mode" // on iPad 'Command Line Interface'
        }
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    
    // MARK: - Serial events
    
    func serialOpened() {
        enterCLIButton.enabled = true
    }
    
    func serialClosed() {
        enterCLIButton.enabled = false
    }
    
    
    // MARK: - IBActions
    
    @IBAction func enterCLI(sender: AnyObject) {
        
        // load CLI async to speed up process
        MessageView.showProgressHUD("Loading CLI")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("CLIViewController")
            dispatch_async(dispatch_get_main_queue()) {
                MessageView.hideProgressHUD()
                self.presentViewController(vc!, animated: true, completion: nil)
            }
        }
    }
}