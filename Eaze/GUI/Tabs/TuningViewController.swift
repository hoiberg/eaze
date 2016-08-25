//
//  TuningViewController.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 31-08-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//

import UIKit
import QuartzCore

final class TuningViewController: UIViewController, ConfigScreen, MSPUpdateSubscriber, AdjustableTextFieldDelegate, SelectionPopoverDelegate, UIPopoverPresentationControllerDelegate  {
    
    // MARK: - IBOutlets. There's too many of them, I know. In a future update this can be replaced by a sigle referencing outlet collection.
    
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var rollLabel: UILabel!
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var yawLabel: UILabel!
    @IBOutlet weak var altLabel: UILabel?
    @IBOutlet weak var velLabel: UILabel?
    @IBOutlet weak var posLabel: UILabel?
    @IBOutlet weak var posRLabel: UILabel?
    @IBOutlet weak var navRLabel: UILabel?
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var magLabel: UILabel?
    
    @IBOutlet weak var rollP: AdjustableTextField!
    @IBOutlet weak var rollI: AdjustableTextField!
    @IBOutlet weak var rollD: AdjustableTextField!
    @IBOutlet weak var pitchP: AdjustableTextField!
    @IBOutlet weak var pitchI: AdjustableTextField!
    @IBOutlet weak var pitchD: AdjustableTextField!
    @IBOutlet weak var yawP: AdjustableTextField!
    @IBOutlet weak var yawI: AdjustableTextField!
    @IBOutlet weak var yawD: AdjustableTextField!
    @IBOutlet weak var altP: AdjustableTextField?
    @IBOutlet weak var altI: AdjustableTextField?
    @IBOutlet weak var altD: AdjustableTextField?
    @IBOutlet weak var velP: AdjustableTextField? // Note that VEL is not in the right place according to Multiwii PID order
    @IBOutlet weak var velI: AdjustableTextField?
    @IBOutlet weak var velD: AdjustableTextField?
    @IBOutlet weak var posP: AdjustableTextField?
    @IBOutlet weak var posI: AdjustableTextField?
    @IBOutlet weak var posRP: AdjustableTextField?
    @IBOutlet weak var posRI: AdjustableTextField?
    @IBOutlet weak var posRD: AdjustableTextField?
    @IBOutlet weak var navRP: AdjustableTextField?
    @IBOutlet weak var navRI: AdjustableTextField?
    @IBOutlet weak var navRD: AdjustableTextField?
    @IBOutlet weak var levelP: AdjustableTextField!
    @IBOutlet weak var levelI: AdjustableTextField!
    @IBOutlet weak var levelD: AdjustableTextField!
    @IBOutlet weak var magP: AdjustableTextField?
    
    @IBOutlet weak var throttleGraph: UIView!
    @IBOutlet weak var rcGraph: UIView!
    @IBOutlet weak var thrMid: AdjustableTextField!
    @IBOutlet weak var thrExp: AdjustableTextField!
    @IBOutlet weak var rcRate: AdjustableTextField!
    @IBOutlet weak var rcExp: AdjustableTextField!
    @IBOutlet weak var rollRate: AdjustableTextField!
    @IBOutlet weak var pitchRate: AdjustableTextField!
    @IBOutlet weak var yawRate: AdjustableTextField!
    @IBOutlet weak var tpa: AdjustableTextField!
    @IBOutlet weak var tpaBreakPoint: AdjustableTextField!
    @IBOutlet weak var yawExpo: AdjustableTextField!
    
    @IBOutlet weak var PIDControllerButton: UIButton!
    @IBOutlet weak var flightProfileButton: UIButton!
    @IBOutlet weak var saveButton: AnyObject!
    @IBOutlet weak var reloadButton: AnyObject!
    
    @IBOutlet weak var fieldHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak var graphMarginConstraint: NSLayoutConstraint?
    @IBOutlet weak var graphHeightConstraint: NSLayoutConstraint?
    
    
    // MARK: - Variables
    
    private let mspCodes = [MSP_PID, MSP_PID_CONTROLLER, MSP_RC_TUNING, MSP_STATUS]
    private var PIDFields: [[AdjustableTextField?]]!,
                selectedPIDController = 0
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // send data request
        msp.addSubscriber(self, forCodes: mspCodes)
        
        // populate helper array
        PIDFields = [[rollP, rollI, rollD], [pitchP, pitchI, pitchD], [yawP, yawI, yawD],
            [altP, altI, altD], [posP, posI, nil], [posRP, posRI, posRD],
            [navRP, navRI, navRD], [levelP, levelI, levelD], [magP, nil, nil], [velP, velI, velD]]
        
        PIDControllerButton.setTitle("-", forState: .Normal)

        // setup graphs
        for graph in [throttleGraph, rcGraph] {
            graph.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.05)
            graph.layer.masksToBounds = true
        }
        
        // fields with max value of 255
        for field in [rollD, pitchD, yawD, altD, velD, levelD] {
            field?.maxValue = 255
            field?.minValue = 0.0
            field?.decimal = 0
            field?.increment = 1
        }
        
        // fields with max value of 25.5
        for field in [rollP, pitchP, yawP, levelP, altP, velP, posRP, navRP, magP] {
            field?.maxValue = 25.5
            field?.minValue = 0.0
            field?.decimal = 1
            field?.increment = 0.1
        }
        
        // fields with max value of 2.55
        for field in [posP, posI, navRI, posRI, yawRate] {
            field?.maxValue = 2.55
            field?.minValue = 0.0
            field?.decimal = 2
            field?.increment = 0.01
        }
        
        // fields with max value of .255
        for field in [rollI, pitchI, yawI, altI, velI, levelI, posRD, navRD] {
            field?.maxValue = 0.255
            field?.minValue = 0.0
            field?.decimal = 3
            field?.increment = 0.001
        }
        
        // field with max value of 1.0
        for field in [rollRate, pitchRate, tpa, thrMid, thrExp, rcRate, rcExp, yawExpo] {
            field?.maxValue = 1.0
            field?.minValue = 0.0
            field?.decimal = 2
            field?.increment = 0.01
        }
        
        // the exceptions
        tpaBreakPoint.intValue = 1000
        tpaBreakPoint.maxValue = 2000
        tpaBreakPoint.minValue = 1000
        tpaBreakPoint.decimal = 0
        tpaBreakPoint.increment = 1
        rcRate.maxValue = 2.5
        rcRate.doubleValue = 1.0
        thrMid.doubleValue = 0.5
        
        // some adjustments for different iPhone sizes
        if UIDevice.isPhone {
            let screenHeight = UIScreen.mainScreen().bounds.height
            if screenHeight < 568 {
                // 3.5"
                fieldHeightConstraint?.constant = 24
            } else if screenHeight < 667 {
                // 4"
                fieldHeightConstraint?.constant = 30
            } else if screenHeight < 736 {
                // 4.7"
                fieldHeightConstraint?.constant = 33
                graphMarginConstraint?.constant = 8
                graphHeightConstraint?.constant = 100
            } else {
                // 5.5"
                fieldHeightConstraint?.constant = 35
                graphMarginConstraint?.constant = 8
                graphHeightConstraint?.constant = 110
            }
        }
        
        notificationCenter.addObserver(self, selector: #selector(TuningViewController.serialOpened), name: SerialOpenedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(TuningViewController.serialClosed), name: SerialClosedNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // note: because the adjustabletextfield delegate function is called before this
        // the graphs might show a wrong setting for a split second
        reloadThrottleGraph()
        reloadRCGraph()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    func willBecomePrimaryView() {
        // called when our tab is selected
        if bluetoothSerial.isConnected {
            sendDataRequest()
            serialOpened()
        } else {
            serialClosed()
        }
    }
    
    func reloadRCGraph() {
        // clear graphs
        rcGraph.layer.sublayers = nil
        
        // mathemagics (taken from desktop configurator)
        let width = rcGraph.frame.width,
            height = rcGraph.frame.height,
            rate = CGFloat(rcRate.doubleValue),
            expo = CGFloat(rcExp.doubleValue),
            ratey = height * rate,
            cony = height - ((ratey / 2.0) * (1.0 - expo))
        
        // add path
        let path = UIBezierPath(),
            layer = CAShapeLayer()
        path.moveToPoint(CGPoint(x: 0, y: height))
        path.addQuadCurveToPoint(CGPoint(x: width, y: height - ratey), controlPoint: CGPoint(x: width / 2.0, y: cony))
        layer.path = path.CGPath
        layer.strokeColor = UIColor.cleanflightGreen().CGColor // not using tincolor here - cuz that might return grey if called
        layer.lineWidth = 2.0 // during the modalViewController presentation.
        layer.fillColor = UIColor.clearColor().CGColor
        rcGraph.layer.addSublayer(layer)
    }
    
    func reloadThrottleGraph() {
        // clear previous graph
        throttleGraph.layer.sublayers = nil

        // mathemagics (taken from desktop configurator)
        let width = throttleGraph.frame.width,
            height = throttleGraph.frame.height,
            mid = CGFloat(thrMid.doubleValue),
            expo = CGFloat(thrExp.doubleValue),
            midx = width * mid,
            midxl = midx * 0.5,
            midxr = (((width - midx) * 0.5) + midx),
            midy = height - (midx * (height/width)),
            midyl = height - ((height - midy) * 0.5 * (expo + 1)),
            midyr = (midy / 2) * (expo + 1)
        
        // add path
        let path = UIBezierPath(),
            layer = CAShapeLayer()
        path.moveToPoint(CGPoint(x: 0, y: height))
        path.addQuadCurveToPoint(CGPoint(x: midx, y: midy), controlPoint: CGPoint(x: midxl, y: midyl))
        path.moveToPoint(CGPoint(x: midx, y: midy))
        path.addQuadCurveToPoint(CGPoint(x: width, y: 0), controlPoint: CGPoint(x: midxr, y: midyr))
        layer.path = path.CGPath
        layer.strokeColor = UIColor.cleanflightGreen().CGColor
        layer.lineWidth = 2.0
        layer.fillColor = UIColor.clearColor().CGColor
        throttleGraph.layer.addSublayer(layer)
    }

    
    // MARK: - Data request / update
    
    func sendDataRequest() {
        if dataStorage.apiVersion >= pidControllerChangeMinApiVersion {
            msp.sendMSP(mspCodes)
        } else {
            msp.sendMSP(mspCodes.arrayByRemovingObject(MSP_PID_CONTROLLER))
        }
    }
    
    func mspUpdated(code: Int) {
        switch code {
            
        case MSP_PID:
            for (index, item) in PIDFields.enumerate() {
                item[0]?.doubleValue = dataStorage.PIDs[index][0]
                item[1]?.doubleValue = dataStorage.PIDs[index][1]
                item[2]?.doubleValue = dataStorage.PIDs[index][2]
            }
            
        //case MSP_PIDNAMES:
        //    if dataStorage.PIDNames.count == 10 {
        //        let PIDLabels: [UILabel?] = [rollLabel, pitchLabel, yawLabel, altLabel, posLabel, posRLabel, navRLabel, levelLabel, magLabel, velLabel]
        //        for (index, item) in PIDLabels.enumerate() {
        //            item?.text = dataStorage.PIDNames[index]
        //        }
        //   }

        case MSP_PID_CONTROLLER:
            selectedPIDController = dataStorage.PIDController
            PIDControllerButton.setTitle(dataStorage.PIDControllerNames[safe: selectedPIDController] ?? "?", forState: .Normal)
            
        case MSP_RC_TUNING:
            rcRate.doubleValue = dataStorage.rcRate
            rcExp.doubleValue = dataStorage.rcExpo
            thrMid.doubleValue = dataStorage.throttleMid
            thrExp.doubleValue = dataStorage.throttleExpo
            yawRate.doubleValue = dataStorage.yawRate
            tpa.doubleValue = dataStorage.dynamicThrottlePID
            if dataStorage.apiVersion < "1.7.0" {
                rollRate.doubleValue = dataStorage.rollPitchRate
                pitchRate.doubleValue = dataStorage.rollPitchRate
                tpaBreakPoint.hidden = true
            } else {
                rollRate.doubleValue = dataStorage.rollRate
                pitchRate.doubleValue = dataStorage.pitchRate
                tpaBreakPoint.intValue = dataStorage.dynamicThrottleBreakpoint
                tpaBreakPoint.hidden = false
            }
            if dataStorage.apiVersion >= "1.10.0" {
                yawExpo.doubleValue = dataStorage.yawExpo
                yawExpo.hidden = false
            } else {
                yawExpo.hidden = true
            }
            
            reloadThrottleGraph()
            reloadRCGraph()
            
        case MSP_STATUS:
            var str = "\(dataStorage.profile+1)"
            if UIDevice.isPhone { str = "Profile " + str + "  ▾" }
            flightProfileButton.setTitle(str, forState: .Normal)

        default:
            log(.Warn, "TuningViewController received unimplemented MSP code: \(code)")
        }
    }
    
    
    // MARK: - Serial events
    
    func serialOpened() {
        if isBeingShown {
            sendDataRequest()
        }
        
        if UIDevice.isPhone {
            (saveButton as! UIBarButtonItem).enabled = true
            (reloadButton as! UIBarButtonItem).enabled = true
        } else {
            (saveButton as! UIButton).enabled = true
            (reloadButton as! UIButton).enabled = true
        }
    }
    
    func serialClosed() {
        if UIDevice.isPhone {
            (saveButton as! UIBarButtonItem).enabled = false
            (reloadButton as! UIBarButtonItem).enabled = false
        } else {
            (saveButton as! UIButton).enabled = false
            (reloadButton as! UIButton).enabled = false
        }
    }

    
    // MARK: - AdjustableTextField
    
    func adjustableTextFieldChangedValue(field: AdjustableTextField) {
        if field == thrMid || field == thrExp {
            reloadThrottleGraph()
        } else if field == rcRate || field == rcExp {
            reloadRCGraph()
        } else if dataStorage.apiVersion < "1.7.0" && pitchRate.doubleValue != rollRate.doubleValue /* prevents infinite loop */ {
            if field == pitchRate  {
                rollRate.doubleValue = pitchRate.doubleValue
            } else {
                pitchRate.doubleValue = rollRate.doubleValue
            }
        }
    }
    
    
    // MARK: - CCPopoverSelection
    
    func popoverSelectedOption(option: Int, tag: Int) {
        if tag == 0 {
            // new PID Controller selected
            PIDControllerButton.setTitle(dataStorage.PIDControllerNames[safe: option] ?? "-", forState: .Normal)
            selectedPIDController = option
        } else {
            // new flight profile selected
            guard bluetoothSerial.isConnected else { return }
            let alert = UIAlertController(title: "Change flight profile?", message: "Unsaved changes will be lost.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Confirm", style: .Destructive) { _ in
                    var str = "\(dataStorage.profile+1)"
                    if UIDevice.isPhone { str = "Profile " + str + "  ▾" }
                    self.flightProfileButton.setTitle(str, forState: .Normal)
                    dataStorage.profile = option
                    msp.crunchAndSendMSP(MSP_SELECT_SETTING) {
                        MessageView.show("Changed Flight Profile")
                        self.sendDataRequest()
                    }
                })
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }

    
    // MARK: - IBActions
    
    @IBAction func save(sender: AnyObject) {
        // MSP_SET_PID
        for (i, fields) in PIDFields.enumerate() {
            for (j, field) in fields.enumerate() {
                dataStorage.PIDs[i][j] = field?.doubleValue ?? 0.0
            }
        }
        
        // MSP_SET_RC_TUNING
        dataStorage.rcRate = rcRate.doubleValue
        dataStorage.rcExpo = rcExp.doubleValue
        dataStorage.throttleMid = thrMid.doubleValue
        dataStorage.throttleExpo = thrExp.doubleValue
        dataStorage.rollPitchRate = rollRate.doubleValue
        if dataStorage.apiVersion >= "1.7.0" {
            dataStorage.rollRate = rollRate.doubleValue
            dataStorage.pitchRate = pitchRate.doubleValue
            dataStorage.dynamicThrottleBreakpoint = tpaBreakPoint.intValue
        }
        dataStorage.yawRate = yawRate.doubleValue
        if dataStorage.apiVersion >= "1.10.0" {
            dataStorage.yawExpo = yawExpo.doubleValue
        }
        dataStorage.dynamicThrottlePID = tpa.doubleValue
        
        var codes = [MSP_SET_PID, MSP_SET_RC_TUNING]
        
        // MSP_SET_PID_CONTROLLER
        if dataStorage.apiVersion >= pidControllerChangeMinApiVersion {
            dataStorage.PIDController = selectedPIDController
            codes.append(MSP_SET_PID_CONTROLLER)
        }
        
        msp.crunchAndSendMSP(codes) {
            msp.sendMSP(MSP_EEPROM_WRITE, callback: self.sendDataRequest) // save and reload
        }
    }
    
    @IBAction func reload(sender: AnyObject) {
        sendDataRequest()
    }
    
    @IBAction func selectPIDController(sender: UIButton) {
        let rect = CGRect(x: sender.frame.origin.x + sender.frame.size.width/2.0, y: sender.frame.origin.y - 2.0 + sender.frame.size.height, width: 1.0, height: 1.0)
        SelectionPopover.presentWithOptions( dataStorage.PIDControllerNames,
                                   delegate: self,
                                        tag: 0,
                                 sourceRect: rect,
                                 sourceView: view,
                                       size: CGSize(width: 250, height: 200),
                   permittedArrowDirections: [.Down, .Up])
    }
    
    @IBAction func selectFlightProfile(sender: UIButton) {
        let rect: CGRect!
        
        if UIDevice.isPhone {
            let point = CGPoint(x: sender.frame.origin.x + sender.frame.size.width/2.0, y: sender.frame.origin.y - 2.0 + sender.frame.size.height),
                origin = sender.convertPoint(point, toView: view)
            rect = CGRect(origin: origin, size: CGSize(width: 1.0, height: 1.0))
        } else {
            rect = CGRect(x: sender.frame.origin.x + sender.frame.size.width/2.0, y: sender.frame.origin.y - 2.0 + sender.frame.size.height, width: 1.0, height: 1.0)
        }
        
        SelectionPopover.presentWithOptions( UIDevice.isPhone ? ["Profile 1", "Profile 2", "Profile 3"] : ["1", "2", "3"],
                                   delegate: self,
                                        tag: 1,
                                 sourceRect: rect,
                                 sourceView: view,
                                       size: CGSize(width: 250, height: 200),
                   permittedArrowDirections: [.Down, .Up])
    }
}