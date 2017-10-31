//
//  MessageView.swift
//  CleanflightMobile
//
//  Created by Alex on 31-03-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

final class MessageView: UIView {
    
    // MARK: - Class Variables
    
    static fileprivate var currentMessage: MessageView?
    static fileprivate let showTime = 1.25
    
    
    // MARK: - Variables
    
    var timer: Timer?,
        label: UILabel!,
        imageView: UIImageView!,
        ownWindow: UIWindow?
    
    var text: String {
        set {
            DispatchQueue.main.async {
                self.label.text = newValue
                self.imageView.frame.origin.x = self.superview!.bounds.width/2 - self.label.intrinsicContentSize.width/2 - 35
                if self.imageView.frame.origin.x < 5 {
                    self.imageView.frame.origin.x = -44 // to prevent cut-off images
                }
            }
        }
        get {
            return label.text ?? ""
        }
    }

    
    // MARK: - Class Functions
    
    class func show(_ text: String) {
        DispatchQueue.main.async {
            if let msg = currentMessage {
                msg.text = text
                msg.timer?.invalidate()
                msg.timer = Timer.scheduledTimer(timeInterval: showTime, target: msg, selector: #selector(MessageView.hide), userInfo: nil, repeats: false)
            } else {
                currentMessage = MessageView()
                currentMessage?.text = text
                currentMessage?.show()
            }
        }
    }
    
    class func showProgressHUD() {
        MRProgressOverlayView.showOverlayAdded(to: UIApplication.shared.windows.first!, title: "", mode: .indeterminate, animated: true)
    }
    
    class func showProgressHUD(_ title: String) {
        MRProgressOverlayView.showOverlayAdded(to: UIApplication.shared.windows.first!, title: title, mode: .indeterminate, animated: true)
    }
    
    class func hideProgressHUD() {
        MRProgressOverlayView.dismissOverlay(for: UIApplication.shared.windows.first!, animated: true)
    }
    
    
    // MARK: - Functions
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init() {
        super.init(frame: CGRect.zero)
        
        // set own views stuff
        self.frame = CGRect(x: 0, y: -70, width: UIScreen.main.bounds.width, height: 70)
        backgroundColor = UIColor.clear
        
        // create blurview
        let blur = UIBlurEffect(style: .dark),
            blurView = UIVisualEffectView(effect: blur)
        blurView.frame = bounds
        addSubview(blurView)
        
        // create vibrancyview
        let vibrancy = UIVibrancyEffect(blurEffect: blur),
            vibrancyView = UIVisualEffectView(effect: vibrancy)
        vibrancyView.frame = bounds
        blurView.contentView.addSubview(vibrancyView)
        
        // create label
        label = UILabel(frame: blurView.frame)
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = .center
        vibrancyView.contentView.addSubview(label)
        
        // create imageView for checkmark
        imageView = UIImageView(frame: CGRect(x: 0, y: 22, width: 26, height: 26))
        imageView.image = UIImage(named: "Success")
        vibrancyView.contentView.addSubview(imageView)
    }
    
    func show() {
        //TODO: Status bar changes color when showing the messageview.. no solution yet.
        ownWindow = UIWindow()
        ownWindow!.windowLevel = /*UIWindowLevelStatusBar + 1*/ UIWindowLevelAlert + 10
        ownWindow!.isUserInteractionEnabled = false
        ownWindow!.backgroundColor = UIColor.clear
        ownWindow!.isHidden = false
        ownWindow!.addSubview(self)
    
        UIView.animate(withDuration: 0.2, animations: {
            self.frame.origin.y = 0
        }) 

        timer = Timer.scheduledTimer(timeInterval: MessageView.showTime, target: self, selector: #selector(MessageView.hide), userInfo: nil, repeats: false)
    }
    
    @objc func hide() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, animations: {
                    self.frame.origin.y = -70
                }, completion: { _ in
                    self.removeFromSuperview()
                    MessageView.currentMessage = nil // delete self
            })
        }
    }
}
