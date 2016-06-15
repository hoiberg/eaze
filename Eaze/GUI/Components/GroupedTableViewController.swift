//
//  PrefsTableViewController.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 27-08-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//
//  *** Don't forget to call super.willdisplaycell etc if you override the method! ***
//

import UIKit
import QuartzCore

///  Subclass this UITableViewController for all static tableViews (for e.g. preferences).
class GroupedTableViewController: UITableViewController {
    
    let margin = CGFloat(12)
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard UIDevice.isPad else { return }
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: margin*2+20, bottom: 0, right: margin*2+20)
        tableView.backgroundColor = globals.colorTableBackground
        tableView.separatorStyle = .None
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // !! Don't forget to call super.willdisplaycell etc if you override this method !!
        // credits of this code go to 'jvanmetre' on http://stackoverflow.com/questions/18822619
        // though I modified it a bit; it no longer just modifies the background, but it actually resizes the cell (which makes it easier concerning IB stuff)
        guard UIDevice.isPad else { return }
        if (cell.respondsToSelector(Selector("tintColor"))){
            if (tableView == self.tableView) {
                
                cell.layoutMargins = UIEdgeInsets(top: 0, left: margin*2+20, bottom: 0, right: margin*2+20)
                cell.contentView.preservesSuperviewLayoutMargins = true
                cell.backgroundColor = UIColor.clearColor()

                let cornerRadius : CGFloat = 5.0
                let pathRef:CGMutablePathRef = CGPathCreateMutable()
                let bounds: CGRect = CGRectInset(cell.bounds, margin * 2, 0)
                
                var addLine: Bool = false
                
                if (indexPath.row == 0 && indexPath.row == tableView.numberOfRowsInSection(indexPath.section)-1) {
                    CGPathAddRoundedRect(pathRef, nil, bounds, cornerRadius, cornerRadius)
                } else if (indexPath.row == 0) {
                    CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds))
                    CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius)
                    CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius)
                    CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))
                    addLine = true
                } else if (indexPath.row == tableView.numberOfRowsInSection(indexPath.section)-1) {
                    CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds))
                    CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius)
                    CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius)
                    CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds))
                } else {
                    CGPathAddRect(pathRef, nil, bounds)
                    addLine = true
                }
                
                let layer: CAShapeLayer = CAShapeLayer()
                layer.path = pathRef
                layer.fillColor = globals.colorCellBackground.CGColor
                
                if (addLine == true) {
                    let lineLayer: CALayer = CALayer()
                    let lineHeight: CGFloat = (1.0 / UIScreen.mainScreen().scale)
                    lineLayer.frame = CGRectMake(CGRectGetMinX(bounds)+10, bounds.size.height-lineHeight, bounds.size.width-10, lineHeight)
                    lineLayer.backgroundColor = tableView.separatorColor!.CGColor
                    layer.addSublayer(lineLayer)
                }
                
                let backGroundView: UIView = UIView(frame: bounds)
                backGroundView.layer.insertSublayer(layer, atIndex: 0)
                backGroundView.backgroundColor = UIColor.clearColor()
                cell.backgroundView = backGroundView
                
                let selectionLayer = CAShapeLayer()
                selectionLayer.path = pathRef
                selectionLayer.fillColor = globals.colorTableSelectedBackground.CGColor
                
                let selectionView: UIView = UIView(frame: bounds)
                selectionView.layer.insertSublayer(selectionLayer, atIndex: 0)
                selectionView.backgroundColor = UIColor.clearColor()
                cell.selectedBackgroundView = selectionView
            }
        }
    }
}
