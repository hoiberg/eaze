//
//  CLIViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 26-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

class CLIViewController: UIViewController, BluetoothSerialDelegate, UITextFieldDelegate {
    
    // MARK: - IBOutlets

    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var mainTextView: UITextView!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter.addObserver(self, selector: #selector(serialClosed), name: Notification.Name.Serial.closed, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)

        // to dismiss the keyboard if the user taps outside the textField while editing
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // style the bottom UIView
        bottomView.layer.masksToBounds = false
        bottomView.layer.shadowOffset = CGSize(width: 0, height: -1)
        bottomView.layer.shadowRadius = 0
        bottomView.layer.shadowOpacity = 0.5
        bottomView.layer.shadowColor = UIColor.gray.cgColor
        
        // remove any dummy text from IB
        mainTextView.text = ""
        
        if UIDevice.isPhone {
            inputField.placeholder = "Type your commands here" // shorter placeholder than on iPad
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        log("Entering CLI mode")
        bluetoothSerial.delegate = self

        if bluetoothSerial.isConnected && !cliActive {
            cliActive = true
            bluetoothSerial.sendStringToDevice("#") // send a '#' to enter cli mode
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputField.becomeFirstResponder()
    }
    
    deinit {
        if cliActive {
            log("Exiting CLI mode")
            bluetoothSerial.sendStringToDevice("exit\r")
            cliActive = false
            bluetoothSerial.delegate = msp
        }
        notificationCenter.removeObserver(self)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func scrollToBottom() {
        let range = NSMakeRange(NSString(string: mainTextView.text).length - 1, 1)
        mainTextView.scrollRangeToVisible(range)
    }
    
    
    // MARK: - Serial Port stuff
    
    func serialPortReceivedData(_ data: Data) {
        if let string = String(data: data, encoding: String.Encoding.utf8) {
            mainTextView.text! += string
            scrollToBottom()
        }
    }
    
    @objc func serialClosed() {
        cliActive = false
        bluetoothSerial.delegate = msp
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Keyboard handling
    
    @objc func keyboardWillShow(_ notification: Notification) {
        // animate the text field to stay above the keyboard
        var info = notification.userInfo!
        let value = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardFrame = value.cgRectValue
        
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 1, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
            self.view.layoutIfNeeded()
            }, completion: { Bool -> Void in
                self.scrollToBottom()
        })
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        // bring the text field back down..
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 1, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
          }, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        inputField.resignFirstResponder()
    }
    
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !bluetoothSerial.isConnected {
            return false
        } else {
            bluetoothSerial.sendStringToDevice("\(inputField.text!)\r")
            inputField.text = ""
            return true
        }
    }
    
    
    // MARK: - IBActions
    
    @IBAction func displayActions(_ sender: UIButton) {
        // display an actionsheet with the options 'exit' and 'help'
        let helpAction = UIAlertAction(title: "Help!", style: .default, handler: { _ in
            let browser = SwiftModalWebVC(urlString: "https://github.com/cleanflight/cleanflight/blob/master/docs/Cli.md")
            self.present(browser, animated: true, completion: nil)
        })
        
        let exitAction = UIAlertAction(title: "Exit CLI", style: .destructive, handler: { _ in
            // send 'exit\r' wait 5 seconds for the flight controller to reboot
            log("Exiting CLI mode")
            bluetoothSerial.sendStringToDevice("exit\r")
            MessageView.showProgressHUD("Waiting for FC to exit CLI mode")
            delay(5) {
                cliActive = false
                bluetoothSerial.delegate = msp
                self.dismiss(animated: true, completion: {
                    MessageView.hideProgressHUD()
                })
            }

        })
        
        let actionSheet = UIAlertController(title: nil, message: "Choosing 'Exit' will cause the flightcontroller to reboot. Unsaved changes will be lost", preferredStyle: .actionSheet)
        actionSheet.addAction(exitAction)
        actionSheet.addAction(helpAction)
        
        if UIDevice.isPad {
            actionSheet.modalPresentationStyle = .popover
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        } else {
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            actionSheet.addAction(cancelAction)
        }
        
        present(actionSheet, animated: true, completion: nil)
    }    
}
