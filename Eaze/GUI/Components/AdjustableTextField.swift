//
//  AdjustableTextField.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 05-09-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//

import UIKit
import QuartzCore

protocol AdjustableTextFieldDelegate {
    func adjustableTextFieldChangedValue(field: AdjustableTextField)
}

final class AdjustableTextField: UIView, UITextFieldDelegate, DecimalPadPopoverDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet var delegate: AnyObject?
    
    
    // MARK: - Variables
    
    var view: UIView!,
        textField: UITextField!,
        plusButton: UIView!,
        minusButton: UIView!,
        plusLabel: UILabel!,
        minusLabel: UILabel!
    
    var increment = 0.1,
        minValue: Double?,
        maxValue: Double?,
        realValue = 0.0
    
    var suffix: String? {
        didSet { reloadText() }
    }
    
    var decimal: Int = 2 {
        didSet { reloadText() }
    }
    
    var enabled: Bool = true {
        didSet { textField.enabled = enabled }
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
            return realValue/*.roundWithDecimals(decimal) // rounding prevents possible gliches (as a double "2" could be "1.99999998")*/
        }
    }
    
    var intValue: Int {
        set { doubleValue = Double(newValue) }
        get { return Int(doubleValue) }
    }
    
    private var touch: UITouch?, // used to differentiate old/new touches
                touchDownTime: NSDate?, // time when the touch was added
                buttonsVisible = false, // self explainatory
                plusButtonIsPressed = false, // self explainatory
                minusButtonIsPressed = false, // self explainatory
                tapOutsideRecognizer: UITapGestureRecognizer! // used when editing with decimal pad to detect dismiss event
    
    
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
        backgroundColor = UIColor.clearColor()
        layer.masksToBounds = false
        clipsToBounds = false
        
        // add textfield
        textField = UITextField(frame: bounds)
        textField.delegate = self
        textField.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        textField.userInteractionEnabled = false
        textField.keyboardType = .DecimalPad

        addSubview(textField)
        
        // style the textfield
        textField.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.05)
        textField.borderStyle = UITextBorderStyle.None
        textField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
        textField.textColor = UIColor.blackColor()
        textField.textAlignment = NSTextAlignment.Center
        
        reloadText()
    }
    
    private func reloadText() {
        textField.text = doubleValue.stringWithDecimals(decimal)
        
        if let suf = suffix {
            textField.text! += suf
        }
        
        (delegate as! AdjustableTextFieldDelegate?)?.adjustableTextFieldChangedValue(self)
    }
        
    private func addButtons() {
        var v = self as UIView
        for _ in 0...1 {
            v.superview!.bringSubviewToFront(v) // prevent buttons from being behind other views
            v = v.superview!
        }
        
        let font = UIFont.systemFontOfSize(38),
            width = bounds.width * 1.5,
            height = bounds.height * 2,
            x = bounds.width * -0.25,
            margin = CGFloat(UIDevice.isPhone ? 2 : 5)

        // plusbutton
        plusButton = UIView(frame: CGRect(x: x, y: -height - margin, width: width, height: height))
        let plusMaskPath = UIBezierPath()
        plusMaskPath.moveToPoint(CGPoint(x: 0, y: 0))
        plusMaskPath.addLineToPoint(CGPoint(x: width, y: 0))
        plusMaskPath.addLineToPoint(CGPoint(x: bounds.width * 1.25, y: height))
        plusMaskPath.addLineToPoint(CGPoint(x: bounds.width * 0.25, y: height))
        plusMaskPath.closePath()
        
        let plusMaskLayer = CAShapeLayer()
        plusMaskLayer.frame = plusButton.bounds
        plusMaskLayer.path = plusMaskPath.CGPath
        plusButton.layer.mask = plusMaskLayer
        
        let plusGradient = CAGradientLayer()
        plusGradient.frame = plusButton.bounds
        plusGradient.colors = [tintColor.colorWithAlphaComponent(0).CGColor, tintColor.CGColor, tintColor.CGColor]
        plusGradient.locations = [0.0, 0.8, 1.0]
        plusButton.layer.insertSublayer(plusGradient, atIndex: 0)
        
        insertSubview(plusButton, atIndex: 0)
        
        // minusbutton
        minusButton = UIView(frame: CGRect(x: x, y: bounds.height + margin, width: width, height: height))
        let minusMaskPath = UIBezierPath()
        minusMaskPath.moveToPoint(CGPoint(x: bounds.width * 0.25, y: 0))
        minusMaskPath.addLineToPoint(CGPoint(x: bounds.width * 1.25, y: 0))
        minusMaskPath.addLineToPoint(CGPoint(x: width, y: height))
        minusMaskPath.addLineToPoint(CGPoint(x: 0, y: height))
        minusMaskPath.closePath()
        
        let minusMaskLayer = CAShapeLayer()
        minusMaskLayer.frame = minusButton.bounds
        minusMaskLayer.path = minusMaskPath.CGPath
        minusButton.layer.mask = minusMaskLayer
        
        let minusGradient = CAGradientLayer()
        minusGradient.frame = minusButton.bounds
        minusGradient.colors = [tintColor.CGColor, tintColor.CGColor, tintColor.colorWithAlphaComponent(0).CGColor]
        minusGradient.locations = [0.0, 0.2, 1.0]
        minusButton.layer.insertSublayer(minusGradient, atIndex: 0)
        
        insertSubview(minusButton, atIndex: 0)
        
        // pluslabel
        plusLabel = UILabel(frame: plusButton.frame)
        plusLabel.text = "+"
        plusLabel.textAlignment = .Center
        plusLabel.textColor = UIColor.whiteColor()
        plusLabel.font = font
        addSubview(plusLabel)
        
        plusLabel.layer.shadowRadius = 2.0
        plusLabel.layer.shadowOpacity = 1.0
        plusLabel.layer.shadowOffset = CGSizeZero
        plusLabel.layer.shadowColor = tintColor.CGColor
        
        // minus label
        minusLabel = UILabel(frame: minusButton.frame)
        minusLabel.text = "-"
        minusLabel.textAlignment = .Center
        minusLabel.textColor = UIColor.whiteColor()
        minusLabel.font = font
        addSubview(minusLabel)
        
        minusLabel.layer.shadowRadius = 2.0
        minusLabel.layer.shadowOpacity = 1.0
        minusLabel.layer.shadowOffset = CGSizeZero
        minusLabel.layer.shadowColor = tintColor.CGColor
        
        buttonsVisible = true
    }
    
    private func removeButtons() {
        guard buttonsVisible else { return }
        plusButton.removeFromSuperview()
        minusButton.removeFromSuperview()
        plusLabel.removeFromSuperview()
        minusLabel.removeFromSuperview()
        plusButton = nil
        minusButton = nil
        plusLabel = nil
        minusLabel = nil
        buttonsVisible = false
        plusButtonIsPressed = false
        minusButtonIsPressed = false
    }
    
    private func presentKeyboard() {
        // show either keyboard or decimal pad
        if UIDevice.isPhone {
            tapOutsideRecognizer = UITapGestureRecognizer(target: self, action: #selector(AdjustableTextField.textFieldShouldReturn(_:)))
            tapOutsideRecognizer.cancelsTouchesInView = false
            window!.rootViewController!.view.addGestureRecognizer(tapOutsideRecognizer)
            
            textField.userInteractionEnabled = true
            textField.becomeFirstResponder()
        } else {
            DecimalPadPopover.presentWithDelegate( self,
                                             text: doubleValue.stringWithDecimals(decimal),
                                       sourceRect: textField.frame,
                                       sourceView: self,
                                             size: CGSize(width: 210, height: 280),
                         permittedArrowDirections: UIPopoverArrowDirection.Any)
        }
    }
    
    private func makeIncrement() {
        // handle positive increment
        if plusButtonIsPressed {
            if maxValue != nil && doubleValue + increment > maxValue {
                // exceeds maxValue
                doubleValue = maxValue!
                return
            } else {
                // make increment & calculate interval to next makeIncrement()
                doubleValue += increment
                let y = (touch!.locationInView(self).y * -1) - 5,
                    maxY = bounds.height * 3,
                    min = 0.1,
                    max = 0.6,
                    multiplier = (maxY - y) / maxY,
                    interval = (max - min) * Double(multiplier < 0 ? 0 : multiplier) + min
                
                delay(interval, callback: makeIncrement)
            }
            
        // handle negative increment
        } else if minusButtonIsPressed {
            // is lower than minValue
            if minValue != nil && doubleValue - increment < minValue {
                doubleValue = minValue!
                return
            } else {
                // make increment & calculate interval to next makeIncrement()
                doubleValue -= increment
                let y = touch!.locationInView(self).y - bounds.height - 5,
                    maxY = bounds.height * 3,
                    min = 0.1,
                    max = 0.6,
                    multiplier = (maxY - y) / maxY,
                    interval = (max - min) * Double(multiplier < 0 ? 0 : multiplier) + min
                
                delay(interval, callback: makeIncrement)
            }
        }
    }

    
    // MARK: - Touches
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard enabled && !buttonsVisible && !textField.editing else { return } // ignore new touches
        touch = touches.first // keep reference
        touchDownTime = NSDate() // create timestamp
        delay(0.12) { // delay appearance buttons
            guard self.touch != nil else { return } // touch might already have been ended by now
            self.addButtons() // if not, finally add the buttons
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard enabled else { return }
        for t in touches {
            if t == touch {
                if buttonsVisible {
                    removeButtons()
                } else {
                    presentKeyboard() // it was a short tap
                }
                
                touch = nil
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard enabled else { return }
        for t in touches {
            if t == touch {
                let yValue = t.locationInView(self).y
                if buttonsVisible && !plusButtonIsPressed && yValue < -5 {
                    // start positive increment
                    plusButtonIsPressed = true
                    makeIncrement()

                } else if buttonsVisible && plusButtonIsPressed && yValue > -5 {
                    // stop positive increment
                    plusButtonIsPressed = false

                } else if buttonsVisible && !minusButtonIsPressed && yValue > bounds.height + 5 {
                    // start negative increment
                    minusButtonIsPressed = true
                    makeIncrement()
                    
                } else if buttonsVisible && minusButtonIsPressed && yValue < bounds.height + 5 {
                    // stop negative increment
                    minusButtonIsPressed = false
                }
            }
        }
    }
    
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        doubleValue = Double(textField.text!.floatValue)
        textField.userInteractionEnabled = false
        tapOutsideRecognizer = nil
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
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
    
    
    // MARK: - DecimalPadPopoverDelegate
    
    func updateText(newText: String) {
        textField.text = newText
    }
    
    func decimalPadWillDismiss() {
        doubleValue = Double(textField.text!.floatValue)
    }
}