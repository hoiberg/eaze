//
//  AdjustableTextField.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 05-09-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//
//TODO: Min knop werkt niet altijd


import UIKit
import QuartzCore

protocol StaticAdjustableTextFieldDelegate {
    func staticAdjustableTextFieldChangedValue(field: StaticAdjustableTextField)
}

final class StaticAdjustableTextField: UIView, UITextFieldDelegate, DecimalPadPopoverDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet var delegate: AnyObject?
    
    
    // MARK: - Variables
    
    var view: UIView!
    
    var increment: Double = 0.1,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        realValue = 0.0
    
    var decimal: Int = 2 {
        didSet {
            reloadText()
        }
    }
    
    var enabled: Bool = true {
        didSet {
            textField.enabled = enabled
            plusButton.enabled = enabled
            minusButton.enabled = enabled
        }
    }
    
    var doubleValue: Double {
        set {
            if maxValue != nil && newValue > maxValue {
                realValue = maxValue!
            } else if minValue != nil && newValue < minValue {
                realValue = minValue!
            } else {
                realValue = newValue
            }
            reloadText()
        }
        get {
            return realValue.roundWithDecimals(decimal) // rounding prevents possible gliches (as a double "2" could be "1.99999998")
        }
    }
    
    var intValue: Int {
        get { return Int(doubleValue) }
        set { doubleValue = Double(newValue) }
    }
    
    private var startPressTime: NSDate?,
                adjustedIncrement: Double = 0.0,
                repeatTimer: NSTimer?,
                disableDelegateUpdate = false,
                tapOutsideRecognizer: UITapGestureRecognizer!

    
    // MARK: - Functions
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        // load our view from nib and add it with correct autoresizingmasks
        let bundle = NSBundle(forClass: self.dynamicType),
            nib = UINib(nibName: "StaticAdjustableTextField", bundle: bundle)
        view = nib.instantiateWithOwner(self, options: nil).first as! UIView
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        addSubview(view)
        
        view.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        
        // style the textfield
        textField.delegate = self
        textField.textColor = UIColor.blackColor()
        textField.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.05)
        textField.textAlignment = NSTextAlignment.Center
        textField.borderStyle = UITextBorderStyle.None
        textField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
        
        reloadText()
    }
    
    func repeatUpdate() {
        if let max = maxValue {
            if doubleValue + adjustedIncrement > max {
                doubleValue = max
                repeatTimer?.invalidate()
                startPressTime = nil
                return
            }
        }
        if let min = minValue {
            if doubleValue + adjustedIncrement < min {
                doubleValue = min
                repeatTimer?.invalidate()
                startPressTime = nil
                return
            }
        }
        
        doubleValue += adjustedIncrement
    }
    
    private func reloadText() {
        textField.text = doubleValue.stringWithDecimals(decimal)
        if !disableDelegateUpdate {
            (delegate as! StaticAdjustableTextFieldDelegate?)?.staticAdjustableTextFieldChangedValue(self)
        } else {
            disableDelegateUpdate = false
        }
    }
    
    func disableNextDelegateCall() {
        disableDelegateUpdate = true
    }
    
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        // show either keyboard or decimal pad
        if UIDevice.isPhone {
            tapOutsideRecognizer = UITapGestureRecognizer(target: self, action: #selector(StaticAdjustableTextField.tapOutside))
            tapOutsideRecognizer.cancelsTouchesInView = false
            window!.rootViewController!.view.addGestureRecognizer(tapOutsideRecognizer)
            return true
        } else {
            DecimalPadPopover.presentWithDelegate(  self,
                text: textField.text!,
                sourceRect: textField.frame,
                sourceView: self,
                size: CGSize(width: 210, height: 280),
                permittedArrowDirections: UIPopoverArrowDirection.Any)
            return false
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        doubleValue = Double(textField.text!.floatValue)
        tapOutsideRecognizer = nil
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        (delegate as! StaticAdjustableTextFieldDelegate?)?.staticAdjustableTextFieldChangedValue(self)
        
        // allow backspace
        if string.isEmpty { return true }
        
        // only allow 0123456789. and , to be put in the textfield
        if string.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "0123456789.,").invertedSet) != nil { return false }
        
        // replace ,'s with .'s
        if string.containsString(",") {
            let newString = string.stringByReplacingOccurrencesOfString(",", withString: ".")
            textField.text = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: newString)
            return false
        }
        
        return true
    }
    
    func tapOutside() {
        textField.resignFirstResponder()
    }
    
    
    // MARK: - DecimalPadPopoverDelegate
    
    func updateText(newText: String) {
        textField.text = newText
    }
    
    func decimalPadWillDismiss() {
        doubleValue = Double(textField.text!.floatValue)
    }
    
    
    // MARK: - IBActions
    
    @IBAction func buttonTouchDown(sender: UIButton) {
        guard enabled else { return }
        
        if sender == plusButton {
            adjustedIncrement = increment
        } else {
            adjustedIncrement = -increment
        }
        
        startPressTime = NSDate()
        repeatTimer = NSTimer.scheduledTimerWithTimeInterval( 0.3,
                                                      target: self,
                                                    selector: #selector(StaticAdjustableTextField.repeatUpdate),
                                                    userInfo: nil,
                                                     repeats: true)
    }
    
    @IBAction func buttonTouchUp(sender: UIButton) {
        guard enabled else { return }
        
        if startPressTime?.timeIntervalSinceNow > -0.05 {
            // increment one last time, but not when we're going to show the keyboard
            doubleValue += adjustedIncrement
        }
        
        repeatTimer?.invalidate()
        startPressTime = nil
    }
}