//
//  GlassBox.swift
//  CleanflightMobile
//
//  Created by Alex on 14-04-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

@IBDesignable
final class GlassBox: UIView {
    
    // MARK: - Variables
    
    fileprivate var label: UILabel!
    
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
        backgroundColor = UIColor.black.withAlphaComponent(0.18)

        label = UILabel(frame: UIEdgeInsetsInsetRect(bounds, UIEdgeInsets(top: 2, left: 4, bottom: 0, right: 0)))
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.white
        label.textAlignment = .left
        label.numberOfLines = 2
        addSubview(label)
        
        reloadText()
    }
    
    func reloadText() {
        let firstAttr: [NSAttributedStringKey: Any] = [NSAttributedStringKey.foregroundColor: label.textColor, NSAttributedStringKey.font: label.font],
            secondAttr: [NSAttributedStringKey: Any] = [NSAttributedStringKey.foregroundColor: label.textColor.withAlphaComponent(0.5), NSAttributedStringKey.font: label.font]
        
        let attributedString = NSMutableAttributedString(string: firstUpperText + " ", attributes: firstAttr)
        attributedString.append(NSAttributedString(string: secondUpperText + "\n", attributes: secondAttr))
        attributedString.append(NSAttributedString(string: firstLowerText + " ", attributes: firstAttr))
        attributedString.append(NSAttributedString(string: secondLowerText, attributes: secondAttr))

        label.attributedText = attributedString
    }
}
