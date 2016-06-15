//
//  EFIS.swift
//  CleanflightMobile
//
//  Created by Alex on 04-04-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//
//  Height horizon moving part total height = 2x (screen diagonal + screen height)
//                             0 - 90 part = screen height
//

import UIKit

@IBDesignable
final class EFIS: UIView {
    
    class Horizon: UIView {
        override func drawRect(rect: CGRect) {
            let context = UIGraphicsGetCurrentContext()!,
                efis = superview as! EFIS,
                height = bounds.height,
                width = bounds.width,
                hMiddle = height/2,
                proportion = Double(efis.bounds.height/height)
            
            // gradient helper function: location 0 = top 1 = bottom
            func drawGradientInRect(rect: CGRect, color1: UIColor, color2: UIColor, loc1: Double, loc2: Double) {
                let colorSpace = CGColorSpaceCreateDeviceRGB(),
                    locations = [CGFloat(loc1), CGFloat(loc2)],
                    colors = [color1.CGColor, color2.CGColor],
                    point1 = CGPoint(x: rect.midX, y: rect.minY),
                    point2 = CGPoint(x: rect.midX, y: rect.maxY),
                    gradient = CGGradientCreateWithColors(colorSpace, colors, locations)
                
                CGContextSaveGState(context)
                CGContextAddRect(context, rect)
                CGContextClip(context)
                //CGContextDrawRadialGradient(context, gradient, point2, width/2, point1, width/2, [])
                CGContextDrawLinearGradient(context, gradient, point1, point2, [])
                CGContextRestoreGState(context)
            }
            
            // upper blue background 0x3498db
            drawGradientInRect(CGRect(x: 0, y: 0, width: width, height: hMiddle),
                               color1: UIColor(hex: 0x50CEC4), // light
                               color2: UIColor(hex: 0x4BA4CE), // dark
                               loc1: 1.0,
                               loc2: 1.0 - proportion
                )
            
            // bottom brown background 0xA17917
            drawGradientInRect(CGRect(x: 0, y: hMiddle, width: width, height: hMiddle),
                               color1: UIColor(hex: 0xCD5313), // light
                               color2: UIColor(hex: 0x8E460F), // dark
                               loc1: 0.0,
                               loc2: proportion
                )
        }
    }
    
    class HorizonLines: UIView {
        override func drawRect(rect: CGRect) {
            let context = UIGraphicsGetCurrentContext()!,
            efis = superview!.superview as! EFIS,
            height = bounds.height,
            width = bounds.width,
            hMiddle = height/2
            
            // middle stroke
            CGContextSetLineWidth(context, 3.0)
            CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
            CGContextMoveToPoint(context, 0, hMiddle)
            CGContextAddLineToPoint(context, width, hMiddle)
            CGContextStrokePath(context)
            
            // major lines
            let oneDegree = efis.bounds.height / 90, // space one degree takes vertically
                lineLength = efis.compass.bounds.width * 0.4, // horz length of a major line
                lineInset = (width - lineLength) / 2, // horz space to/from ends
                verticalPart: CGFloat = 0.0, // the vert length of a 'tick' up or down at each line end
                positions: [CGFloat] = [10, 20, 30, 40, 50, 70, 90] // locations of major lines
            
            let fontAttributes = [
                NSFontAttributeName: UIFont.boldSystemFontOfSize(20),
                NSForegroundColorAttributeName: UIColor.whiteColor()
            ]
            
            CGContextSetLineWidth(context, 2.0)
            
            func drawMajorLine(pos: CGFloat) {
                let y = hMiddle + pos * oneDegree,
                    v = pos < 0 ? verticalPart : -verticalPart
                
                CGContextMoveToPoint(context, lineInset, y + v)
                CGContextAddLineToPoint(context, lineInset, y)
                CGContextAddLineToPoint(context, lineInset + lineLength, y)
                CGContextAddLineToPoint(context, lineInset + lineLength, y + v)
                CGContextStrokePath(context)
                
                let str = "\(Int(abs(pos)))" as NSString,
                point = CGPoint(x: lineInset + lineLength + 10, y: y - 13)
                
                str.drawAtPoint(point, withAttributes: fontAttributes)
            }
            
            for pos in positions {
                drawMajorLine(pos)
                drawMajorLine(-pos)
            }
            
            // minor (small) lines
            let sLineLength = lineLength * 0.6,
                sLineInset = (width - sLineLength) / 2,
                sPositions: [CGFloat] = [5, 15, 25, 35, 45, 55]
            
            CGContextSetLineWidth(context, 1.0)
            
            func drawMinorLine(pos: CGFloat) {
                let y = hMiddle + pos * oneDegree
                
                CGContextMoveToPoint(context, sLineInset, y)
                CGContextAddLineToPoint(context, sLineInset + sLineLength, y)
                CGContextStrokePath(context)
            }
            
            for pos in sPositions {
                drawMinorLine(pos)
                drawMinorLine(-pos)
            }
        }
    }

    class Overlay: UIView {
        override func drawRect(rect: CGRect) {
            let context = UIGraphicsGetCurrentContext()!,
                efis = superview as! EFIS,
                height = bounds.height,
                width = bounds.width,
                hMiddle = height * efis.verticalMiddle,
                wMiddle = width/2
            
            // arrow in the middle
            let arrowMiddleHeight: CGFloat = efis.smallScreen ? 20 : 30, // heigth in the middle
                arrowWidth: CGFloat = efis.smallScreen ? 52 : 80, // half width in points
                arrowHeight: CGFloat = efis.smallScreen ? 28 : 42 // height of the entire arrow
            
            // upper halve
            CGContextMoveToPoint(context, wMiddle, hMiddle)
            CGContextAddLineToPoint(context, wMiddle - arrowWidth, hMiddle + arrowHeight)
            CGContextAddLineToPoint(context, wMiddle, hMiddle + arrowMiddleHeight/2 + 2)
            CGContextAddLineToPoint(context, wMiddle + arrowWidth, hMiddle + arrowHeight)
            CGContextClosePath(context)
            
            CGContextSetFillColorWithColor(context, UIColor(hex: 0xEFE110).CGColor) // EFE110 0xF4D03F
            CGContextFillPath(context)
            
            // lower halve
            CGContextMoveToPoint(context, wMiddle, hMiddle + arrowMiddleHeight/2)
            CGContextAddLineToPoint(context, wMiddle - arrowWidth, hMiddle + arrowHeight)
            CGContextAddLineToPoint(context, wMiddle, hMiddle + arrowMiddleHeight)
            CGContextAddLineToPoint(context, wMiddle + arrowWidth, hMiddle + arrowHeight)
            CGContextClosePath(context)
            
            CGContextSetFillColorWithColor(context, UIColor(hex: 0xA2A704).CGColor) // EFE110 FFA400
            CGContextFillPath(context)
            
         /*   // translucent rects
            let boxWidth = 50 as CGFloat,
                sideMargin = efis.sideMargin,
                maxHeight = efis.verticalMiddle * height * 2,
                topMargin = maxHeight * 0.05,
                boxHeight = maxHeight - topMargin * 2,
                box = CGRect(x: sideMargin, y: topMargin, width: boxWidth, height: boxHeight), // left
                box2 = CGRect(x: width - sideMargin - boxWidth, y: topMargin, width: boxWidth, height: boxHeight) // right
            
            CGContextSetFillColorWithColor(context, UIColor(hexWithAlpha: 0x00000080).CGColor)
            CGContextSetStrokeColorWithColor(context, UIColor(hex: 0xFFFFFF).CGColor)
            CGContextSetLineWidth(context, 2.0)
            
            CGContextAddRect(context, box)
            CGContextFillPath(context)
            CGContextStrokePath(context)
            
            CGContextAddRect(context, box2)
            CGContextFillPath(context)
            CGContextStrokePath(context)*/
            
            if !efis.smallScreen {
                // heading label background
                let boxHeight = efis.smallScreen ? 40 : 50 as CGFloat, // height of box
                    boxWidth = boxHeight * 0.65, // half width of top box
                    boxBottomWidth = boxWidth * 1.2, // half width on the bottom
                    boxArrowHeight = boxHeight * 0.5, // height of pointy thing under box
                    boxBottomMargin = boxArrowHeight * 0.5, // distance between circle and bottom pointy thingy
                    boxBottom = efis.horizonLinesMask.frame.minY
                
                CGContextMoveToPoint(context, wMiddle, boxBottom - boxBottomMargin)
                CGContextAddLineToPoint(context, wMiddle - boxBottomWidth, boxBottom - boxBottomMargin - boxArrowHeight)
                CGContextAddLineToPoint(context, wMiddle - boxWidth,       boxBottom - boxBottomMargin - boxArrowHeight - boxHeight)
                CGContextAddLineToPoint(context, wMiddle + boxWidth,       boxBottom - boxBottomMargin - boxArrowHeight - boxHeight)
                CGContextAddLineToPoint(context, wMiddle + boxBottomWidth, boxBottom - boxBottomMargin - boxArrowHeight)
                CGContextClosePath(context)
                
                CGContextSetFillColorWithColor(context, UIColor.whiteColor().colorWithAlphaComponent(0.08).CGColor) // White 0.1 alpha
                CGContextFillPath(context)
            }
        }
    }
    
    class Compass: UIView {
        override func drawRect(rect: CGRect) {
            let context = UIGraphicsGetCurrentContext()!,
                efis = superview as! EFIS,
                width = bounds.width,
                wMiddle = width/2
            
            // arrow
            let arrowMiddleHeight: CGFloat = efis.smallScreen ? 16 : 24, // heigth in the middle
                arrowWidth: CGFloat = efis.smallScreen ? 10 : 15, // half width in points
                arrowHeight: CGFloat = efis.smallScreen ? 20 : 30 // height of the entire arrow
            
            // upper halve
            CGContextMoveToPoint(context, wMiddle, 0)
            CGContextAddLineToPoint(context, wMiddle - arrowWidth, arrowHeight)
            CGContextAddLineToPoint(context, wMiddle, arrowMiddleHeight/2 + 2)
            CGContextAddLineToPoint(context, wMiddle + arrowWidth, arrowHeight)
            CGContextClosePath(context)
            
            CGContextSetFillColorWithColor(context, UIColor(hex: 0xEFE110).CGColor) // EFE110 0xF4D03F
            CGContextFillPath(context)
            
            // lower halve
            CGContextMoveToPoint(context, wMiddle, arrowMiddleHeight/2)
            CGContextAddLineToPoint(context, wMiddle - arrowWidth, arrowHeight)
            CGContextAddLineToPoint(context, wMiddle, arrowMiddleHeight)
            CGContextAddLineToPoint(context, wMiddle + arrowWidth, arrowHeight)
            CGContextClosePath(context)
            
            CGContextSetFillColorWithColor(context, UIColor(hex: 0xA2A704).CGColor) // EFE110 FFA400
            CGContextFillPath(context)
        }
    }
    
    
    // MARK: - Variables
    
    @IBInspectable var smallScreen: Bool = false // normaly we'd use isPhone, but we need this in IB
    var verticalMiddle: CGFloat = 0.5 // vertical middle of horizon, 0 = top 1 = bottom
    
    var roll = 0.0 {
        didSet {
            let rad = roll * M_PI / 180.0
            horizon.transform = CGAffineTransformMakeRotation(CGFloat(rad))
            horizonLines.transform = CGAffineTransformMakeRotation(CGFloat(rad))
        }
    }
    
    var pitch = 0.0 {
        didSet {
            let oneDegree = (bounds.height / horizon.bounds.height) / 90
            horizon.layer.anchorPoint.y = oneDegree * CGFloat(pitch) + 0.5
            horizonLines.layer.anchorPoint.y = oneDegree * CGFloat(pitch) + 0.5
        }
    }
    
    var heading = 0.0 {
        didSet {
            let rad = heading * M_PI / 180.0
            compass.transform = CGAffineTransformMakeRotation(CGFloat(rad))
            headingLabel?.text = "\(Int(heading))"
        }
    }
    
    private var horizon: Horizon!, // the moving part of the horizon (colors)
                horizonLines: HorizonLines!, // the moving part of the horizon (lines)
                horizonLinesMask: UIView!, // masks the previous view and therefore static
                compass: Compass!, // the rotating part of the compass
                overlay: Overlay!, // the static overlay on top of the horizon
                headingLabel: UILabel?,
                speedLabel: UILabel!,
                altitudeLabel: UILabel!,
                featuresLabels: [UILabel]!
    
    
    // MARK: - Functions
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        //setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    
    func setup() {
        // for some reason IB's value of smallScreen won't be used on an actual device
        if UIDevice.isPhone {
            smallScreen = true
        }
        
        print(bounds.height)
        
        // some defs
        let height = bounds.height,
            width = bounds.width,
            diagonal = sqrt(pow(height, 2) + pow(width, 2))
            //maxHeight = verticalMiddle * height * 2
        
        // calculate radius of circle in the middle
        var radius: CGFloat!
        if smallScreen {
            if UIScreen.mainScreen().bounds.size.height < 568 {
                // 3.5"
                radius = width * 0.3
            } else {
                // iPhone >3.5"
                radius = width * 0.36
            }
        } else {
            // iPad
            radius = width * 0.2
        }
        
        // horizon colors
        let hWidth = height * 2,
            hHeight = (diagonal + height) * 2
        
        horizon = Horizon(frame: CGRect(x: (width-hWidth)/2,
                                        y: (height-hHeight)/2 - (0.5-verticalMiddle) * height,
                                    width: hWidth,
                                   height: hHeight))
        
        
        // horizon lines superview
        let linesSuperView = UIView(frame: bounds) // used so maskview has effect
        linesSuperView.opaque = false
        linesSuperView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.08)

        
        // horizon lines
        horizonLines = HorizonLines(frame: horizon.frame)
        horizonLines.opaque = false
        horizonLines.backgroundColor = UIColor.clearColor()

        
        // horizon mask
        horizonLinesMask = UIView(frame: CGRect(x: width/2 - radius,
                                                y: height*verticalMiddle - radius,
                                            width: radius*2,
                                           height: radius*2))
        horizonLinesMask.backgroundColor = UIColor.whiteColor()
        horizonLinesMask.layer.cornerRadius = radius
        
        print(height*verticalMiddle)

        // compass rotating part
        compass = Compass(frame: horizonLinesMask.frame)
        compass.opaque = false
        compass.backgroundColor = UIColor.clearColor()

        
        // overlay (arrow etc)
        overlay = Overlay(frame: bounds)
        overlay.opaque = false
        overlay.backgroundColor = UIColor.clearColor()
        
        if !smallScreen {
            // heading label
            let labelHeight = (smallScreen ? 40 : 50) as CGFloat, // label width
                labelWidth = labelHeight * 1.6,
                labelBottomMargin = labelWidth * 0.40
            headingLabel = UILabel(frame: CGRect(x: frame.midX - labelWidth/2,
                                                 y: compass.frame.minY - labelHeight - labelBottomMargin,
                                             width: labelWidth,
                                            height: labelHeight))
            headingLabel!.textAlignment = .Center
            headingLabel!.textColor = UIColor.whiteColor()
            headingLabel!.font = UIFont.boldSystemFontOfSize(smallScreen ? 30 : 35)
            headingLabel!.text = "0"
        }

        // labels
     /*   let labelWidth: CGFloat = 70,
            labelHeight: CGFloat = 35,
            labelArrowWidth: CGFloat = 10
        
        // heading label
        headingLabel = UILabel(frame: CGRect(x: (width-labelWidth)/2,
                                             y: horizonLinesMask.frame.minY - labelHeight - labelArrowWidth - 2,
                                         width: labelWidth,
                                        height: labelHeight
            ))
        headingLabel.textAlignment = .Center
        headingLabel.textColor = UIColor.whiteColor()
        headingLabel.font = UIFont.boldSystemFontOfSize(20)
        headingLabel.text = "000"
        
        /let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: 0, y: 0))
        path.addLineToPoint(CGPoint(x: labelWidth, y: 0))
        path.addLineToPoint(CGPoint(x: labelWidth, y: labelHeight))
        path.addLineToPoint(CGPoint(x: labelWidth * 0.75, y: labelHeight))
        path.addLineToPoint(CGPoint(x: labelWidth * 0.5, y: labelHeight + labelArrowWidth))
        path.addLineToPoint(CGPoint(x: labelWidth * 0.25, y: labelHeight))
        path.addLineToPoint(CGPoint(x: 0, y: labelHeight))
        path.closePath() //TODO: HIER VERDER
        
        let layer = CAShapeLayer()
        layer.frame = headingLabel.bounds
        layer.path = path.CGPath
        layer.fillColor = UIColor.clearColor().CGColor
        layer.strokeColor = UIColor.whiteColor().CGColor
        layer.lineWidth = 2
        
        headingLabel.layer.masksToBounds = false
        headingLabel.layer.insertSublayer(layer, atIndex: 0)*/


        
        addSubview(horizon)
        addSubview(linesSuperView)
        addSubview(horizonLinesMask)
        addSubview(compass)
        addSubview(overlay)
        if !smallScreen { addSubview(headingLabel!) }
        
        linesSuperView.maskView = horizonLinesMask
        linesSuperView.addSubview(horizonLines)
    }
}