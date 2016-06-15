//
//  GlassBox.swift
//  CleanflightMobile
//
//  Created by Alex on 14-04-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

@IBDesignable
class GlassBox: UIView {
    
    // MARK: - Variables
    
    private var label: UILabel!
    
    var firstUpperText = "",
        secondUpperText = "",
        firstLowerText = "",
        secondLowerText = ""
    

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
        //backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.08)

        label = UILabel(frame: UIEdgeInsetsInsetRect(bounds, UIEdgeInsets(top: 2, left: 4, bottom: 0, right: 0)))
        //label.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        label.font = UIFont.systemFontOfSize(13)
        label.textColor = UIColor.whiteColor()
        label.textAlignment = .Left
        label.numberOfLines = 2
        addSubview(label)
        
        reloadText()
    }
    
    func reloadText() {
        let firstAttr = [NSForegroundColorAttributeName: label.textColor, NSFontAttributeName: label.font],
            secondAttr = [NSForegroundColorAttributeName: label.textColor.colorWithAlphaComponent(0.5), NSFontAttributeName: label.font]
        
        let attributedString = NSMutableAttributedString(string: firstUpperText + " ", attributes: firstAttr)
        attributedString.appendAttributedString(NSAttributedString(string: secondUpperText + "\n", attributes: secondAttr))
        attributedString.appendAttributedString(NSAttributedString(string: firstLowerText + " ", attributes: firstAttr))
        attributedString.appendAttributedString(NSAttributedString(string: secondLowerText, attributes: secondAttr))

        label.attributedText = attributedString
    }
}