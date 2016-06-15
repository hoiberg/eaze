//
//  StatusLabel.swift
//  CleanflightMobile
//
//  Created by Alex on 14-04-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

@IBDesignable
final class GlassLabel: UIView {

    enum Background: Int {
        case Red, Green, Dark
    }
    
    // MARK: - Variables
    
    private var label: UILabel!
    
    var background: Background! {
        didSet {
            switch background! {
            case .Red:
                //backgroundColor = UIColor(hex: 0xD16363).colorWithAlphaComponent(0.4)
                backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.08)
            case .Green:
                backgroundColor = UIColor(hex: 0x417505).colorWithAlphaComponent(0.4)
            case .Dark:
                backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
            }
        }
    }
    
    @IBInspectable dynamic var text: String {
        get { return label.text ?? "" }
        set { label.text = newValue }
    }
    
    @IBInspectable dynamic var backgroundOption: Int {
        get { return background.rawValue }
        set { background = Background(rawValue: newValue > 2 ? 0 : newValue) }
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
        label = UILabel(frame: bounds)
        label.frame.origin.y += 1
        label.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        label.font = UIFont.systemFontOfSize(13)
        label.textColor = UIColor.whiteColor()
        label.textAlignment = .Center
        addSubview(label)
        
        layer.cornerRadius = frame.height/2
        background = .Dark
    }
    
    func adjustToTextSize() {
        frame.size.width = label.intrinsicContentSize().width + 20
    }
}