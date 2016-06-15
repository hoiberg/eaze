//
//  CleanButton.swift
//  CCGUITestApp
//
//  Created by Alex on 23-08-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//

import UIKit
import QuartzCore


@IBDesignable
final class CleanButton: UIButton {
    
    override func prepareForInterfaceBuilder() {
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    private func setup() {
        
        // functions for changing the background color
        self.addTarget(self, action: #selector(CleanButton.touchDown), forControlEvents: [.TouchDown, .TouchDragInside])
        self.addTarget(self, action: #selector(CleanButton.touchUp), forControlEvents: [.TouchDragExit, .TouchUpInside])
        
        // border
        layer.borderColor = globals.colorTint.CGColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 5.0
        layer.masksToBounds = false
        clipsToBounds = false
        
        // font
        titleLabel?.font = UIFont(name: "HelveticaNeue", size: 15)
        
        // image
        imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)

        // color
        backgroundColor = UIColor.clearColor()
        setTitleColor(globals.colorTint, forState: UIControlState.Normal)
        setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        setTitleColor(globals.colorTextOnTint, forState: UIControlState.Selected)
        setTitleColor(globals.colorTextOnTint, forState: UIControlState.Highlighted)
        showsTouchWhenHighlighted = false

    }
    
    func touchDown() {
        backgroundColor = globals.colorTint
    }
    
    func touchUp() {
        backgroundColor = UIColor.clearColor()
    }
}