//
//  CLIViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 26-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

//TODO: CLI not exited when quitting app while in CLI mode

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
        
        notificationCenter.addObserver(self, selector: #selector(CLIViewController.serialClosed), name: SerialClosedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(CLIViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(CLIViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)

        // to dismiss the keyboard if the user taps outside the textField while editing
        let tap = UITapGestureRecognizer(target: self, action: #selector(CLIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // style the bottom UIView
        bottomView.layer.masksToBounds = false
        bottomView.layer.shadowOffset = CGSizeMake(0, -1)
        bottomView.layer.shadowRadius = 0
        bottomView.layer.shadowOpacity = 0.5
        bottomView.layer.shadowColor = UIColor.grayColor().CGColor
        
        // remove any dummy text from IB
        mainTextView.text = ""
        
        if UIDevice.isPhone {
            inputField.placeholder = "Type your commands here" // shorter placeholder than on iPad
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        log("Entering CLI mode")
        bluetoothSerial.delegate = self

        if bluetoothSerial.isConnected && !cliActive {
            cliActive = true
            bluetoothSerial.sendStringToDevice("#") // send a '#' to enter cli mode
        }
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
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func scrollToBottom() {
        let range = NSMakeRange(NSString(string: mainTextView.text).length - 1, 1)
        mainTextView.scrollRangeToVisible(range)
    }
    
    
    // MARK: - Serial Port stuff
    
    func serialPortReceivedData(data: NSData) {
        if let string = String(data: data, encoding: NSUTF8StringEncoding) {
            mainTextView.text! += string
            scrollToBottom()
        }
    }
    
    func serialClosed() {
        cliActive = false
        bluetoothSerial.delegate = msp
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Keyboard handling
    
    func keyboardWillShow(notification: NSNotification) {
        // animate the text field to stay above the keyboard
        var info = notification.userInfo!
        let value = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardFrame = value.CGRectValue()
        
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(1, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
            self.view.layoutIfNeeded()
            }, completion: { Bool -> Void in
                self.scrollToBottom()
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // bring the text field back down..
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(1, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
          }, completion: nil)
    }
    
    func dismissKeyboard() {
        inputField.resignFirstResponder()
    }
    
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if !bluetoothSerial.isConnected {
            return false
        } else {
            bluetoothSerial.sendStringToDevice("\(inputField.text!)\r")
            inputField.text = ""
            return true
        }
    }
    
    
    // MARK: - IBActions
    
    @IBAction func displayActions(sender: UIButton) {
        // display an actionsheet with the options 'exit' and 'help'
        let helpAction = UIAlertAction(title: "Help!", style: .Default, handler: { _ in
            let browser = SwiftModalWebVC(urlString: "https://github.com/cleanflight/cleanflight/blob/master/docs/Cli.md")
            self.presentViewController(browser, animated: true, completion: nil)
        })
        
        let exitAction = UIAlertAction(title: "Exit CLI", style: .Destructive, handler: { _ in
            // send 'exit\r' wait 5 seconds for the flight controller to reboot
            log("Exiting CLI mode")
            bluetoothSerial.sendStringToDevice("exit\r")
            MessageView.showProgressHUD("Waiting for FC to exit CLI mode")
            delay(5) {
                cliActive = false
                bluetoothSerial.delegate = msp
                self.dismissViewControllerAnimated(true, completion: {
                    MessageView.hideProgressHUD()
                })
            }

        })
        
        let actionSheet = UIAlertController(title: nil, message: "Choosing 'Exit' will cause the flightcontroller to reboot. Unsaved changes will be lost", preferredStyle: .ActionSheet)
        actionSheet.addAction(exitAction)
        actionSheet.addAction(helpAction)
        
        if UIDevice.isPad {
            actionSheet.modalPresentationStyle = .Popover
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        } else {
            let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            actionSheet.addAction(cancelAction)
        }
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }    
}