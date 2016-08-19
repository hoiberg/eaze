//
//  ModeRangeTableViewCell.swift
//  Eaze
//
//  Created by Alex on 09-08-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//
//  Accepts values 0-2000
//  Bar range is 900-2100
//  'channel' is the aux channel index of range 0-(numberOfChannels minus 1)
//

import UIKit

class ModeRangeTableViewCell: UITableViewCell, MSPUpdateSubscriber, SelectionPopoverDelegate {
    
    // MARK: - IBOutlets

    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var bar: UIView!
    @IBOutlet weak var rangeBar: UIView!
    @IBOutlet weak var indicator: UIView!
    @IBOutlet weak var leftHandle: UIImageView!
    @IBOutlet weak var rightHandle: UIImageView!
    
    @IBOutlet weak var rangeBarLeading: NSLayoutConstraint!
    @IBOutlet weak var rangeBarTrailing: NSLayoutConstraint!
    @IBOutlet weak var indicatorPos: NSLayoutConstraint!
    
    
    // MARK: - Variables
    
    var currentTouch: UITouch?, touchedView: AnyObject!
    
    var modeRange: ModeRange! {
        didSet {
            reloadView()
        }
    }
    
    var currentValue: Int {
        get {
            return Int(((indicator.frame.midX - bar.frame.minX) * 1200.0) / bar.frame.width) + 900
        } set {
            var x = newValue == 0 ? 1500 : newValue
            x = newValue < 900 ? 900 : x
            x = newValue > 2100 ? 2100 : x
            indicatorPos.constant = (CGFloat(x - 900) / 1200.0) * bar.frame.width
        }
    }
    
    override var bounds: CGRect {
        didSet {
            reloadView()
        }
    }
    

    // MARK: - Functions
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        msp.addSubscriber(self, forCodes: [MSP_RC])
        
        bar.addObserver(self, forKeyPath: "bounds", options: .New, context: nil) // to reload constraints
        
        bar.layer.cornerRadius = 3
        bar.layer.masksToBounds = true
        
        rangeBar.backgroundColor = UIColor.cleanflightGreen()
        leftHandle.tint(UIColor.cleanflightGreen())
        rightHandle.tint(UIColor.cleanflightGreen())
    }
    
    deinit {
        bar.removeObserver(self, forKeyPath: "bounds")
    }
    
    func reloadView() {
        guard modeRange != nil else { return }

        rangeBarLeading.constant = CGFloat(modeRange.range.start - 900) / 1200.0 * bar.frame.width
        rangeBarTrailing.constant = CGFloat(1200 - (modeRange.range.end - 900)) / 1200.0 * bar.frame.width
        currentValue = dataStorage.channels[modeRange.auxChannelIndex+4]
        
        UIView.performWithoutAnimation {
            self.button.setTitle("AUX \(self.modeRange.auxChannelIndex+1)", forState: .Normal)
            self.layoutIfNeeded()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if object! === bar && keyPath! == "bounds" {
            if (superview!.superview! as! UITableView).editing == true { return }
            reloadView() // as the constraints use constants, not ratios, we need to refresh them when the bar size changes
        }
    }
    
    
    // MARK: - MSP Update
    
    func mspUpdated(code: Int) {
        // MSP_RC
        currentValue = dataStorage.channels[modeRange.auxChannelIndex+4]
    }
    
    
    // MARK: - Touch handlers
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard currentTouch == nil else { return } // only track one touch
        
        let touch = touches.first!,
            loc = touch.locationInView(self),
            m: CGFloat = 10.0 // margin for bigger touch area
        
        // determine what view is touched
        if leftHandle.frame.minX-m...leftHandle.frame.maxX+m ~= loc.x {
            currentTouch = touch
            touchedView = leftHandle
            
        } else if rightHandle.frame.minX-m...rightHandle.frame.maxX+m ~= loc.x {
            currentTouch = touch
            touchedView = rightHandle

        } else if convertRect(rangeBar.frame.insetBy(dx: 25, dy: -5), fromView: bar).contains(loc) {
            currentTouch = touch
            touchedView = rangeBar
        }
        
        if let _ = touchedView {
            (superview!.superview as! UITableView).scrollEnabled = false
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if touch == currentTouch {
                let mov = touch.locationInView(self).x - touch.previousLocationInView(self).x,
                    minDist: CGFloat = 40
                
                // actions according to touched view
                if touchedView === leftHandle {
                    let new = rangeBarLeading.constant + mov
                    if new < 0 {
                        rangeBarLeading.constant = 0 // too little
                    } else if new > bar.frame.width - rangeBarTrailing.constant - minDist {
                        rangeBarLeading.constant = bar.frame.width - rangeBarTrailing.constant - minDist // too much
                    } else {
                        rangeBarLeading.constant = new // quite right
                    }
                    modeRange.range.start = Int(rangeBar.frame.minX * 1200.0 / bar.frame.width) + 900
                    
                } else if touchedView === rightHandle {
                    let new = rangeBarTrailing.constant - mov
                    if new < 0 {
                        rangeBarTrailing.constant = 0 // too little
                    } else if new > bar.frame.width - rangeBarLeading.constant - minDist {
                        rangeBarTrailing.constant = bar.frame.width - rangeBarLeading.constant - minDist // too much
                    } else {
                        rangeBarTrailing.constant = new // quite right
                    }
                    modeRange.range.end = Int(rangeBar.frame.maxX * 1200.0 / bar.frame.width) + 900
                    
                } else if touchedView === rangeBar {
                    let lNew = rangeBarLeading.constant + mov,
                        tNew = rangeBarTrailing.constant - mov
                    if lNew < 0 {
                        rangeBarTrailing.constant += rangeBarLeading.constant // enfore leading limit
                        rangeBarLeading.constant = 0
                    } else if tNew < 0 {
                        rangeBarLeading.constant += rangeBarTrailing.constant // enforce trailing limit
                        rangeBarTrailing.constant = 0
                    } else {
                        rangeBarLeading.constant = lNew
                        rangeBarTrailing.constant = tNew
                    }
                    modeRange.range.start = Int(rangeBar.frame.minX * 1200.0 / bar.frame.width) + 900
                    modeRange.range.end = Int(rangeBar.frame.maxX * 1200.0 / bar.frame.width) + 900
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if touch == currentTouch {
                (superview!.superview as! UITableView).scrollEnabled = true
                currentTouch = nil
                touchedView = nil
            }
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        for touch in touches ?? [] {
            if touch == currentTouch {
                (superview!.superview as! UITableView).scrollEnabled = true
                currentTouch = nil
                touchedView = nil
            }
        }
    }
    
    
    // MARK: - PopoverSelectionDelegate
    
    func popoverSelectedOption(option: Int, tag: Int) {
        modeRange.auxChannelIndex = option
        currentValue = dataStorage.channels[option+4]
        button.setTitle("AUX \(self.modeRange.auxChannelIndex+1)", forState: .Normal)
    }
    
    
    // MARK: - IBActions
    
    @IBAction func buttonPressed(sender: UIButton) {
        var arr: [String] = []
        for i in 1 ... dataStorage.activeChannels-4 {
            arr.append("AUX \(i)")
        }
        
        let rect = CGRect(x: sender.frame.origin.x + sender.frame.size.width/2.0,
                          y: sender.frame.origin.y - 2.0 + sender.frame.size.height,
                      width: 1.0,
                     height: 1.0)
        
        SelectionPopover.presentWithOptions( arr,
                                   delegate: self,
                                        tag: 0,
                                 sourceRect: rect,
                                 sourceView: self,
                                       size: CGSize(width: 250, height: 200),
                   permittedArrowDirections: [.Down, .Up, .Left, .Right])
    }
}