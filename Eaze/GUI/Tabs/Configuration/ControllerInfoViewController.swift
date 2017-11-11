//
//  ControllerInfoViewController.swift
//  Eaze
//
//  Created by Alex on 31/10/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit

final class ControllerInfoViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var enterControllerButton: UIButton!
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter.addObserver(self, selector: #selector(serialOpened), name: Notification.Name.Serial.opened, object: nil)
        notificationCenter.addObserver(self, selector: #selector(serialClosed), name: Notification.Name.Serial.closed, object: nil)
        
        if !bluetoothSerial.isConnected {
            enterControllerButton.isEnabled = false
        }
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    
    // MARK: - Serial events
    
    @objc func serialOpened() {
        enterControllerButton.isEnabled = true
    }
    
    @objc func serialClosed() {
        enterControllerButton.isEnabled = false
    }
    
    
    // MARK: - IBActions
    
    @IBAction func enterController(_ sender: AnyObject) {
        // load CLI async to speed up process
        MessageView.showProgressHUD("Loading Controller")
        
        // check if the receiver mode is MSP
       msp.sendMSP(MSP_FEATURE) {
            if !dataStorage.BFFeatures.bitCheck(14) {
                let alert = UIAlertController(title: "Receiver Type Incorrect", message: "Please set the receiver type to 'MSP' first.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
                MessageView.hideProgressHUD()
                self.present(alert, animated: true)
                return
            }
            
            msp.sendMSP(MSP_RX_MAP) {
                // now load the controller*/
                DispatchQueue(label: "nl.hangar42.eaze.loadController").async {
                    let sb = UIStoryboard.init(name: "Controller", bundle: Bundle.main)
                    let vc = sb.instantiateViewController(withIdentifier: "ControllerViewController")
                    DispatchQueue.main.async {
                        MessageView.hideProgressHUD()
                        landscapeMode = true
                        self.present(vc, animated: true)
                    }
                }
            }
        }
    }
}
