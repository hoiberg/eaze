//
//  GlassIndicator.swift
//  CleanflightMobile
//
//  Created by Alex on 24-04-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

@IBDesignable
final class GlassIndicator: UIView {
    
    // MARK: - Variables
    
    fileprivate var label: UILabel!,
                detailLabel: UILabel!,
                movingView: UIView!
    
    @IBInspectable var text: String {
        get { return label.text ?? "" }
        set { label.text = newValue   }
    }
    
    @IBInspectable var detailText: String {
        get { return detailLabel.text ?? "" }
        set { detailLabel.text = newValue.uppercased()   }
    }
    
    @IBInspectable var color: UIColor {
        set {
            backgroundColor = newValue.withAlphaComponent(0.25)
            movingView.backgroundColor = newValue.withAlphaComponent(0.1) // was 1.0
        }
        get {
            return backgroundColor ?? UIColor.clear
        }
    }
    
    
    // MARK: - Functions
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }
    
    func setup() {
        layer.cornerRadius = bounds.height/2
        layer.masksToBounds = true
        clipsToBounds = true
        
        movingView = UIView(frame: bounds)
        addSubview(movingView)
        
        let offset: CGFloat = UIDevice.isPhone ? 20 : 21
        
        label = UILabel(frame: CGRect(x: 0, y: bounds.midY-offset, width: bounds.width, height: 32))
        label.font = UIFont.systemFont(ofSize: UIDevice.isPhone ? 25 : 29)
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center
        label.textColor = UIColor.white
        addSubview(label)
        
        let offset2: CGFloat = UIDevice.isPhone ? -3 : 2
        
        detailLabel = UILabel(frame: CGRect(x: 0, y: label.frame.maxY+offset2, width: bounds.width, height: 14))
        detailLabel.font = UIFont.systemFont(ofSize: UIDevice.isPhone ? 12 : 14)
        label.minimumScaleFactor = 0.5
        detailLabel.textAlignment = .center
        detailLabel.textColor = UIColor.white
        addSubview(detailLabel)
        
        setIndication(0.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let temp = [text, detailText],
            c = color
        
        movingView.removeFromSuperview()
        label.removeFromSuperview()
        detailLabel.removeFromSuperview()
        setup()
        
        text = temp[0]
        detailText = temp[1]
        color = c
    }
    
    /// Takes a value of 0.0 to 1.0 and moves the indicator/movingView to the corresponding position
    func setIndication(_ val: Double) {
        movingView.frame.origin.y = CGFloat(1.0-val) * bounds.height
    }
}
