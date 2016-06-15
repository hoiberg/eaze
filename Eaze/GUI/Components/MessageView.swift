//
//  MessageView.swift
//  CleanflightMobile
//
//  Created by Alex on 31-03-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

class MessageView: UIView {
    
    
    // MARK: - Variables
    
    static private var currentMessage: MessageView?
    static private let showTime = 1.25
    
    var timer: NSTimer?
    var label: UILabel!
    var imageView: UIImageView!
    var ownWindow: UIWindow?
    
    var text: String {
        set {
            dispatch_async(dispatch_get_main_queue()) {
                self.label.text = newValue
                self.imageView.frame.origin.x = self.superview!.bounds.width/2 - self.label.intrinsicContentSize().width/2 - 35
                if self.imageView.frame.origin.x < 5 {
                    self.imageView.frame.origin.x = -44 // to prevent cut-off images
                }
            }
        }
        get {
            return label.text ?? ""
        }
    }
    
    
    // MARK: - Functions
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init() {
        super.init(frame: CGRectZero)
        
        // set own views stuff
        self.frame = CGRect(x: 0, y: -70, width: UIScreen.mainScreen().bounds.width, height: 70)
        backgroundColor = UIColor.clearColor()
        
        // create blurview
        let blur = UIBlurEffect(style: .Dark),
            blurView = UIVisualEffectView(effect: blur)
        blurView.frame = bounds
        addSubview(blurView)
        
        // create vibrancyview
        let vibrancy = UIVibrancyEffect(forBlurEffect: blur),
            vibrancyView = UIVisualEffectView(effect: vibrancy)
        vibrancyView.frame = bounds
        blurView.contentView.addSubview(vibrancyView)
        
        // create label
        label = UILabel(frame: blurView.frame)
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFontOfSize(25)
        //label.textColor = UIColor.greenColor()
        label.textAlignment = .Center
        vibrancyView.contentView.addSubview(label)
        
        // create imageView for checkmark
        imageView = UIImageView(frame: CGRect(x: 0, y: 22, width: 26, height: 26))
        imageView.image = UIImage(named: "Success")
        vibrancyView.contentView.addSubview(imageView)
    }
    
    func show() {
        ownWindow = UIWindow()
        ownWindow!.windowLevel = UIWindowLevelStatusBar + 1
        ownWindow!.userInteractionEnabled = false
        ownWindow!.backgroundColor = UIColor.clearColor()
        ownWindow!.hidden = false
        ownWindow!.addSubview(self)
        
        UIView.animateWithDuration(0.2) {
            self.frame.origin.y = 0
        }

        timer = NSTimer.scheduledTimerWithTimeInterval(MessageView.showTime, target: self, selector: #selector(MessageView.hide), userInfo: nil, repeats: false)
    }
    
    func hide() {
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.2, animations: {
                    self.frame.origin.y = -70
                }, completion: { _ in
                    self.removeFromSuperview()
                    MessageView.currentMessage = nil // delete self
            })
        }
    }
    
    class func showProgressHUD() {
        MRProgressOverlayView.showOverlayAddedTo(UIApplication.sharedApplication().windows.first!, title: "", mode: .Indeterminate, animated: true)
    }
    
    class func showProgressHUD(title: String) {
        MRProgressOverlayView.showOverlayAddedTo(UIApplication.sharedApplication().windows.first!, title: title, mode: .Indeterminate, animated: true)
    }

    class func hideProgressHUD() {
        MRProgressOverlayView.dismissOverlayForView(UIApplication.sharedApplication().windows.first!, animated: true)
    }
    
    
    // MARK: - Class Functions
    
    class func show(text: String) {
        dispatch_async(dispatch_get_main_queue()) {
            if let msg = currentMessage {
                msg.text = text
                msg.timer?.invalidate()
                msg.timer = NSTimer.scheduledTimerWithTimeInterval(showTime, target: msg, selector: #selector(MessageView.hide), userInfo: nil, repeats: false)
            } else {
                currentMessage = MessageView()
                currentMessage?.text = text
                currentMessage?.show()
            }
        }
    }
}