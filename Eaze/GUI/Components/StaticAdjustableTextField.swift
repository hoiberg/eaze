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
    var increment: Double = 0.1
    var minValue: Double? = nil
    var maxValue: Double? = nil
    var decimal: Int = 2 { didSet { reloadText() }} // number of digits after comma
    var doubleValue: Double = 0.0 { didSet {
        // MARK: WARNING may lead to infinite loop (setting property in its own didSet)
        if let max = maxValue {
            if doubleValue > max {
                doubleValue = max
            }
        }
        if let min = minValue {
            if doubleValue < min {
                doubleValue = min
            }
        }
        reloadText()
        }}
    var intValue: Int {
        get { return Int(doubleValue) }
        set { doubleValue = Double(newValue) }
    }
    
    var enabled: Bool = true {
        didSet {
            textField.enabled = enabled
            plusButton.enabled = enabled
            minusButton.enabled = enabled
        }
    }
    
    
    private var startPress: NSDate?
    private var previousPress: NSDate?
    private var adjustedIncrement: Double = 0.0
    private let minLongPressTime: NSTimeInterval = 0.05
    private var repeatTimer: NSTimer?
    private var disableDelegateUpdate = false
    private var tapOutsideRecognizer: UITapGestureRecognizer!

    
    
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
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "StaticAdjustableTextField", bundle: bundle)
        view = nib.instantiateWithOwner(self, options: nil).first as! UIView
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        addSubview(view)
        
        view.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        
        // style the textfield
        textField.delegate = self
        textField.textColor = globals.colorTextOnBackground
        textField.backgroundColor = globals.colorTextOnBackground.colorWithAlphaComponent(0.05)
        textField.textAlignment = NSTextAlignment.Center
        textField.borderStyle = UITextBorderStyle.None
        //textField.layer.borderWidth = 1.0
        //textField.layer.borderColor = globals.colorTint.CGColor
        textField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
        
        reloadText()
        
    }
    
    func repeatUpdate() {
        if previousPress?.timeIntervalSinceNow <= -minLongPressTime {
            if let max = maxValue {
                if doubleValue + adjustedIncrement > max {
                    doubleValue = max
                    repeatTimer?.invalidate()
                    startPress = nil
                    previousPress = nil
                    return
                }
            }
            if let min = minValue {
                if doubleValue + adjustedIncrement < min {
                    doubleValue = min
                    repeatTimer?.invalidate()
                    startPress = nil
                    previousPress = nil
                    return
                }
            }
            
            doubleValue += adjustedIncrement
            previousPress = NSDate()
        }
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
        doubleValue = Double(textField.text!.floatValue) //TODO: use nsnumberformatter for localization
        tapOutsideRecognizer = nil
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        (delegate as! StaticAdjustableTextFieldDelegate?)?.staticAdjustableTextFieldChangedValue(self)
        
        // allow backspace
        if string.isEmpty { return true }
        
        // only allow 0123456789. and , to be put in the textfield
        if string.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "0123456789.,").invertedSet) != nil { return false }
        
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
    
    @IBAction func buttonTouchDown(sender: CleanButton) {
        
        if sender == plusButton {
            adjustedIncrement = increment
        } else {
            adjustedIncrement = -increment
        }
        
        startPress = NSDate()
        previousPress = NSDate()
        repeatTimer = NSTimer.scheduledTimerWithTimeInterval(0.3
            , target: self, selector: #selector(StaticAdjustableTextField.repeatUpdate), userInfo: nil, repeats: true)
    }
    
    @IBAction func buttonTouchUp(sender: CleanButton) {
        
        if startPress?.timeIntervalSinceNow > -minLongPressTime {
            doubleValue += adjustedIncrement
        }
        
        repeatTimer?.invalidate()
        startPress = nil
        previousPress = nil
    }
}