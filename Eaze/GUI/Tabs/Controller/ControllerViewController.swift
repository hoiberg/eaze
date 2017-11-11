//
//  ControllerViewController.swift
//  Eaze
//
//  Created by Alex on 01/11/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//
//

import UIKit

enum Side {
    case Left, Right
}

final class ControllerViewController: UIViewController, MSPUpdateSubscriber {
    
    // MARK: - Outlets
    
    @IBOutlet weak var leftBackground: RoundedView!
    @IBOutlet weak var leftStick: RoundedView!
    @IBOutlet weak var rightBackground: RoundedView!
    @IBOutlet weak var rightStick: RoundedView!
    
    @IBOutlet weak var leftX: NSLayoutConstraint!
    @IBOutlet weak var leftY: NSLayoutConstraint!
    @IBOutlet weak var rightX: NSLayoutConstraint!
    @IBOutlet weak var rightY: NSLayoutConstraint!
    
    @IBOutlet weak var aux1: UIButton!
    @IBOutlet weak var aux2: UIButton!
    @IBOutlet weak var aux3: UIButton!
    @IBOutlet weak var aux4: UIButton!
    
    @IBOutlet weak var voltageLabel: UILabel!
    
    
    // MARK: - Variables
    
    var leftTouch: UITouch?
    var rightTouch: UITouch?
    
    var slowTimer: Timer?
    var fastTimer: Timer?
    var mode = 2
    
    var throttle  = 0
    var aileron   = 0
    var elevator  = 0
    var rudder    = 0
    var auxValues = [0, 0, 0, 0]
    
    
    // MARK: - ViewController
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // for voltage label
        msp.addSubscriber(self, forCodes: [MSP_ANALOG])
        
        // for dismiss when closed
        notificationCenter.addObserver(self, selector: #selector(serialClosed), name: Notification.Name.Serial.closed, object: nil)

        // configure buttons
        for btn in [aux1, aux2, aux3, aux4] {
            btn!.titleLabel!.numberOfLines = 2
            btn!.titleLabel!.textAlignment = .center
            btn!.setTitle("Aux \(btn!.tag)\n0", for: .normal)
        }
        
        // reset voltage label
        voltageLabel.text = "---V"
        
        // get stick mode
        mode = userDefaults.integer(forKey: DefaultsControllerModeKey)
        
        // set sticks in default pos
        setLeftX(1500)
        setLeftY(mode == 2 ? 1000 : 1500)
        setRightX(1500)
        setRightY(mode == 1 ? 1000 : 1500)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // set sticks again (in case of resize on iphone)
        setLeftX(1500)
        setLeftY(mode == 2 ? 1000 : 1500)
        setRightX(1500)
        setRightY(mode == 1 ? 1000 : 1500)
        
        // start timer 2Hz
        slowTimer?.invalidate()
        slowTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(sendSlowUpdate), userInfo: nil, repeats: true)
        
        // start timer 20Hz
        fastTimer?.invalidate()
        fastTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(sendFastUpdate), userInfo: nil, repeats: true)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = touch.location(in: view)
            if leftTouch == nil && leftBackground.frame.contains(point) {
                leftTouch = touch
                updateLeftTouch()
            } else if rightTouch == nil && rightBackground.frame.contains(point) {
                rightTouch = touch
                updateRightTouch()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if leftTouch != nil && touches.contains(leftTouch!) {
            updateLeftTouch()
        }
        
        if rightTouch != nil && touches.contains(rightTouch!) {
            updateRightTouch()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if leftTouch != nil && touches.contains(leftTouch!) {
            leftTouch = nil
            setLeftX(1500)
            if mode == 1 {
                setLeftY(1500)
            } else {
                setLeftY(1000)
            }
        }
        
        if rightTouch != nil && touches.contains(rightTouch!) {
            rightTouch = nil
            setRightX(1500)
            if mode == 2 {
                setRightY(1500)
            } else {
                setRightY(1000)
            }
        }
    }
    
    func updateLeftTouch() {
        guard leftTouch != nil else { return }
        let point = leftTouch!.location(in: view),
            center = leftBackground.center,
            width = leftBackground.bounds.width - leftStick.bounds.width,
            height = leftBackground.bounds.height - leftStick.bounds.height,
            dx = point.x - center.x,
            dy = center.y - point.y
        
        var vx = Int((dx / (width/2)) * 500) + 1500,
            vy = Int((dy / (height/2)) * 500) + 1500
        
        if vx > 2000 { vx = 2000 }
        if vx < 1000 { vx = 1000 }
        if vy > 2000 { vy = 2000 }
        if vy < 1000 { vy = 1000 }
        
        setLeftX(vx)
        setLeftY(vy)
    }
    
    func updateRightTouch() {
        guard rightTouch != nil else { return }
        let point = rightTouch!.location(in: view),
            center = rightBackground.center,
            width = rightBackground.bounds.width - rightStick.bounds.width,
            height = rightBackground.bounds.height - rightStick.bounds.height,
            dx = point.x - center.x,
            dy = center.y - point.y
        
        var vx = Int((dx / (width/2)) * 500) + 1500,
            vy = Int((dy / (height/2)) * 500) + 1500
        
        if vx > 2000 { vx = 2000 }
        if vx < 1000 { vx = 1000 }
        if vy > 2000 { vy = 2000 }
        if vy < 1000 { vy = 1000 }
        
        setRightX(vx)
        setRightY(vy)
    }
    
    func setLeftX(_ val: Int) {
        if mode == 1 {
            aileron = val
        } else {
            rudder = val
        }
        
        let a = leftBackground.bounds.width - leftStick.bounds.width,
            b = (CGFloat(val) - 1000.0) / 1000.0

        leftX.constant = a * b
    }
    
    func setLeftY(_ val: Int) {
        if mode == 1 {
            elevator = val
        } else {
            throttle = val
        }
        
        let a = leftBackground.bounds.height - leftStick.bounds.height,
            b = (CGFloat(val) - 1000.0) / 1000.0
        
        leftY.constant = a * b
    }
    
    func setRightX(_ val: Int) {
        if mode == 2 {
            aileron = val
        } else {
            rudder = val
        }
        
        let a = rightBackground.bounds.width - rightStick.bounds.width,
            b = (CGFloat(val) - 1000.0) / 1000.0
        
        rightX.constant = a * b
    }
    
    func setRightY(_ val: Int) {
        if mode == 2 {
            elevator = val
        } else {
            throttle = val
        }
        
        let a = rightBackground.bounds.height - rightStick.bounds.height,
            b = (CGFloat(val) - 1000.0) / 1000.0
        
        rightY.constant = a * b
    }
    
    @objc func sendSlowUpdate() {
        msp.sendMSP(MSP_ANALOG)
    }
    
    @objc func sendFastUpdate() {
        let aert = [aileron, elevator, rudder, throttle] + auxValues
        var channels = [Int](repeating: 0, count: 8)
        for i in 0 ..< dataStorage.RC_MAP.count {
            channels[i] = aert[dataStorage.RC_MAP.index(of: i)!]
        }
        
        print(channels)
        msp.sendRawRC(channels)
    }
    
    
    // MARK: - Serial
    
    func mspUpdated(_ code: Int) {
        // msp_analog
        voltageLabel.text = "\(dataStorage.voltage.stringWithDecimals(1))V"
    }
    
    @objc func serialClosed() {
        close()
    }
    
    
    // MARK: - Actions
    
    @IBAction func auxPressed(_ sender: UIButton) {
        func handler(_ action: UIAlertAction) {
            auxValues[sender.tag-1] = Int(action.title!)!
            [aux1, aux2, aux3, aux4][sender.tag-1]!.setTitle("Aux \(sender.tag)\n\(action.title!)", for: .normal)
        }
        
        let actionSheet = UIAlertController(title: "Select AUX \(sender.tag) value", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "1750", style: .default, handler: handler))
        actionSheet.addAction(UIAlertAction(title: "1500", style: .default, handler: handler))
        actionSheet.addAction(UIAlertAction(title: "1250", style: .default, handler: handler))
        actionSheet.addAction(UIAlertAction(title: "0", style: .default, handler: handler))

        if UIDevice.isPad {
            actionSheet.modalPresentationStyle = .popover
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        } else {
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func close(_ sender: UIButton? = nil) {
        slowTimer?.invalidate()
        fastTimer?.invalidate()
        
        landscapeMode = false
        dismiss(animated: true) {
            
        }
    }
}

@IBDesignable
class RoundedView: UIView {
    @IBInspectable var cornerRadius: Double = 5.0 {
        didSet {
            layer.masksToBounds = true
            layer.cornerRadius = CGFloat(cornerRadius)
        }
    }
}
