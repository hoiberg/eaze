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


protocol AdjustableTextFieldDelegate {
    func adjustableTextFieldChangedValue(_ field: AdjustableTextField)
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
        didSet { textField.isEnabled = enabled }
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
    
    fileprivate var touch: UITouch?, // used to differentiate old/new touches
                touchDownTime: Date?, // time when the touch was added
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
    
    fileprivate func setup() {
        backgroundColor = UIColor.clear
        layer.masksToBounds = false
        clipsToBounds = false
        
        // add textfield
        textField = UITextField(frame: bounds)
        textField.delegate = self
        textField.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        textField.isUserInteractionEnabled = false
        textField.keyboardType = .decimalPad

        addSubview(textField)
        
        // style the textfield
        textField.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        textField.borderStyle = UITextBorderStyle.none
        textField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
        textField.textColor = UIColor.black
        textField.textAlignment = NSTextAlignment.center
        
        reloadText()
    }
    
    fileprivate func reloadText() {
        textField.text = doubleValue.stringWithDecimals(decimal)
        
        if let suf = suffix {
            textField.text! += suf
        }
        
        (delegate as! AdjustableTextFieldDelegate?)?.adjustableTextFieldChangedValue(self)
    }
        
    fileprivate func addButtons() {
        var v = self as UIView
        for _ in 0...1 {
            v.superview!.bringSubview(toFront: v) // prevent buttons from being behind other views
            v = v.superview!
        }
        
        let font = UIFont.systemFont(ofSize: 38),
            width = bounds.width * 1.5,
            height = bounds.height * 2,
            x = bounds.width * -0.25,
            margin = CGFloat(UIDevice.isPhone ? 2 : 5)

        // plusbutton
        plusButton = UIView(frame: CGRect(x: x, y: -height - margin, width: width, height: height))
        let plusMaskPath = UIBezierPath()
        plusMaskPath.move(to: CGPoint(x: 0, y: 0))
        plusMaskPath.addLine(to: CGPoint(x: width, y: 0))
        plusMaskPath.addLine(to: CGPoint(x: bounds.width * 1.25, y: height))
        plusMaskPath.addLine(to: CGPoint(x: bounds.width * 0.25, y: height))
        plusMaskPath.close()
        
        let plusMaskLayer = CAShapeLayer()
        plusMaskLayer.frame = plusButton.bounds
        plusMaskLayer.path = plusMaskPath.cgPath
        plusButton.layer.mask = plusMaskLayer
        
        let plusGradient = CAGradientLayer()
        plusGradient.frame = plusButton.bounds
        plusGradient.colors = [tintColor.withAlphaComponent(0).cgColor, tintColor.cgColor, tintColor.cgColor]
        plusGradient.locations = [0.0, 0.8, 1.0]
        plusButton.layer.insertSublayer(plusGradient, at: 0)
        
        insertSubview(plusButton, at: 0)
        
        // minusbutton
        minusButton = UIView(frame: CGRect(x: x, y: bounds.height + margin, width: width, height: height))
        let minusMaskPath = UIBezierPath()
        minusMaskPath.move(to: CGPoint(x: bounds.width * 0.25, y: 0))
        minusMaskPath.addLine(to: CGPoint(x: bounds.width * 1.25, y: 0))
        minusMaskPath.addLine(to: CGPoint(x: width, y: height))
        minusMaskPath.addLine(to: CGPoint(x: 0, y: height))
        minusMaskPath.close()
        
        let minusMaskLayer = CAShapeLayer()
        minusMaskLayer.frame = minusButton.bounds
        minusMaskLayer.path = minusMaskPath.cgPath
        minusButton.layer.mask = minusMaskLayer
        
        let minusGradient = CAGradientLayer()
        minusGradient.frame = minusButton.bounds
        minusGradient.colors = [tintColor.cgColor, tintColor.cgColor, tintColor.withAlphaComponent(0).cgColor]
        minusGradient.locations = [0.0, 0.2, 1.0]
        minusButton.layer.insertSublayer(minusGradient, at: 0)
        
        insertSubview(minusButton, at: 0)
        
        // pluslabel
        plusLabel = UILabel(frame: plusButton.frame)
        plusLabel.text = "+"
        plusLabel.textAlignment = .center
        plusLabel.textColor = UIColor.white
        plusLabel.font = font
        addSubview(plusLabel)
        
        plusLabel.layer.shadowRadius = 2.0
        plusLabel.layer.shadowOpacity = 1.0
        plusLabel.layer.shadowOffset = CGSize.zero
        plusLabel.layer.shadowColor = tintColor.cgColor
        
        // minus label
        minusLabel = UILabel(frame: minusButton.frame)
        minusLabel.text = "-"
        minusLabel.textAlignment = .center
        minusLabel.textColor = UIColor.white
        minusLabel.font = font
        addSubview(minusLabel)
        
        minusLabel.layer.shadowRadius = 2.0
        minusLabel.layer.shadowOpacity = 1.0
        minusLabel.layer.shadowOffset = CGSize.zero
        minusLabel.layer.shadowColor = tintColor.cgColor
        
        buttonsVisible = true
    }
    
    fileprivate func removeButtons() {
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
    
    fileprivate func presentKeyboard() {
        // show either keyboard or decimal pad
        if UIDevice.isPhone {
            tapOutsideRecognizer = UITapGestureRecognizer(target: self, action: #selector(AdjustableTextField.textFieldShouldReturn(_:)))
            tapOutsideRecognizer.cancelsTouchesInView = false
            window!.rootViewController!.view.addGestureRecognizer(tapOutsideRecognizer)
            
            textField.isUserInteractionEnabled = true
            textField.becomeFirstResponder()
        } else {
            DecimalPadPopover.presentWithDelegate( self,
                                             text: doubleValue.stringWithDecimals(decimal),
                                       sourceRect: textField.frame,
                                       sourceView: self,
                                             size: CGSize(width: 210, height: 280),
                         permittedArrowDirections: UIPopoverArrowDirection.any)
        }
    }
    
    fileprivate func makeIncrement() {
        // handle positive increment
        if plusButtonIsPressed {
            if maxValue != nil && doubleValue + increment > maxValue {
                // exceeds maxValue
                doubleValue = maxValue!
                return
            } else {
                // make increment & calculate interval to next makeIncrement()
                doubleValue += increment
                let y = (touch!.location(in: self).y * -1) - 5,
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
                let y = touch!.location(in: self).y - bounds.height - 5,
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled && !buttonsVisible && !textField.isEditing else { return } // ignore new touches
        touch = touches.first // keep reference
        touchDownTime = Date() // create timestamp
        delay(0.12) { // delay appearance buttons
            guard self.touch != nil else { return } // touch might already have been ended by now
            self.addButtons() // if not, finally add the buttons
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled else { return }
        for t in touches {
            if t == touch {
                let yValue = t.location(in: self).y
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        doubleValue = Double(textField.text!.floatValue)
        textField.isUserInteractionEnabled = false
        tapOutsideRecognizer = nil
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
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
    
    
    // MARK: - DecimalPadPopoverDelegate
    
    func updateText(_ newText: String) {
        textField.text = newText
    }
    
    func decimalPadWillDismiss() {
        doubleValue = Double(textField.text!.floatValue)
    }
}
