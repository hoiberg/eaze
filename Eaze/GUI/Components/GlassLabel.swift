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
        case red, green, dark
    }
    
    // MARK: - Variables
    
    fileprivate var label: UILabel!
    
    var background: Background! {
        didSet {
            switch background! {
            case .red:
                backgroundColor = UIColor.clear
            case .green:
                backgroundColor = UIColor(hex: 0x417505).withAlphaComponent(0.4)
            case .dark:
                backgroundColor = UIColor.black.withAlphaComponent(0.18)
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
        label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.white
        label.textAlignment = .center
        addSubview(label)
        
        layer.cornerRadius = frame.height/2
        background = .dark
    }
    
    func adjustToTextSize() {
        frame.size.width = label.intrinsicContentSize.width + 20
    }
}
