//
//  AdjustableTextField.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 05-09-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//

import UIKit
import QuartzCore
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol StaticAdjustableTextFieldDelegate {
    func staticAdjustableTextFieldChangedValue(_ field: StaticAdjustableTextField)
}

final class StaticAdjustableTextField: UIView, UITextFieldDelegate, DecimalPadPopoverDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet var delegate: AnyObject?
    
    
    // MARK: - Variables
    
    var view: UIView!
    
    var increment = 0.1,
        minValue: Double?,
        maxValue: Double?,
        realValue = 0.0

    var suffix: String? {
        didSet { reloadText() }
    }

    var decimal: Int = 2 {
        didSet {
            reloadText()
        }
    }
    
    var enabled: Bool = true {
        didSet {
            textField.isEnabled = enabled
            plusButton.isEnabled = enabled
            minusButton.isEnabled = enabled
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
    
    fileprivate var startPressTime: Date?,
                adjustedIncrement: Double = 0.0,
                repeatTimer: Timer?,
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
    
    fileprivate func setup() {
        // load our view from nib and add it with correct autoresizingmasks
        let bundle = Bundle(for: type(of: self)),
            nib = UINib(nibName: "StaticAdjustableTextField", bundle: bundle)
        view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(view)
        
        view.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        
        // style the textfield
        textField.delegate = self
        textField.textColor = UIColor.black
        textField.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        textField.textAlignment = NSTextAlignment.center
        textField.borderStyle = UITextBorderStyle.none
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
    
    fileprivate func reloadText() {
        textField.text = doubleValue.stringWithDecimals(decimal)
        
        if let suf = suffix {
            textField.text! += suf
        }

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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // show either keyboard or decimal pad
        if UIDevice.isPhone {
            tapOutsideRecognizer = UITapGestureRecognizer(target: self, action: #selector(StaticAdjustableTextField.tapOutside))
            tapOutsideRecognizer.cancelsTouchesInView = false
            window!.rootViewController!.view.addGestureRecognizer(tapOutsideRecognizer)
            return true
        } else {
            DecimalPadPopover.presentWithDelegate(  self,
                                             text: doubleValue.stringWithDecimals(decimal),
                                       sourceRect: textField.frame,
                                       sourceView: self,
                                             size: CGSize(width: 210, height: 280),
                         permittedArrowDirections: UIPopoverArrowDirection.any)
            return false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        doubleValue = Double(textField.text!.floatValue)
        tapOutsideRecognizer = nil
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        (delegate as! StaticAdjustableTextFieldDelegate?)?.staticAdjustableTextFieldChangedValue(self)
        
        // allow backspace
        if string.isEmpty { return true }
        
        // only allow 0123456789. and , to be put in the textfield
        if string.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789.,").inverted) != nil { return false }
        
        // replace ,'s with .'s
        if string.contains(",") {
            let newString = string.replacingOccurrences(of: ",", with: ".")
            textField.text = (textField.text! as NSString).replacingCharacters(in: range, with: newString)
            return false
        }
        
        return true
    }
    
    func tapOutside() {
        textField.resignFirstResponder()
    }
    
    
    // MARK: - DecimalPadPopoverDelegate
    
    func updateText(_ newText: String) {
        textField.text = newText
    }
    
    func decimalPadWillDismiss() {
        doubleValue = Double(textField.text!.floatValue)
    }
    
    
    // MARK: - IBActions
    
    @IBAction func buttonTouchDown(_ sender: UIButton) {
        guard enabled else { return }
        
        if sender == plusButton {
            adjustedIncrement = increment
        } else {
            adjustedIncrement = -increment
        }
        
        startPressTime = Date()
        repeatTimer = Timer.scheduledTimer( timeInterval: 0.3,
                                                      target: self,
                                                    selector: #selector(StaticAdjustableTextField.repeatUpdate),
                                                    userInfo: nil,
                                                     repeats: true)
    }
    
    @IBAction func buttonTouchUp(_ sender: UIButton) {
        guard enabled else { return }
        
        if startPressTime?.timeIntervalSinceNow > -0.05 {
            // increment one last time, but not when we're going to show the keyboard
            doubleValue += adjustedIncrement
        }
        
        repeatTimer?.invalidate()
        startPressTime = nil
    }
}
