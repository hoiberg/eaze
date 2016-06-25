//
//  CCPopoverSelectionViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 15-10-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

protocol SelectionPopoverDelegate {
    func popoverSelectedOption(option: Int, tag: Int)
}

class SelectionPopover: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    
    // MARK: - Variables
    
    var tableView: UITableView?,
        delegate: SelectionPopoverDelegate?,
        tag = 0 // tag is meant for the delegate to differentiate between different VC's
    
    var options: [String] = [] {
        didSet { tableView?.reloadData() }
    }
    
    
    // MARK: - Class Functions
    
    class func presentWithOptions(options: [String], delegate: SelectionPopoverDelegate, tag: Int, sourceRect: CGRect, sourceView: UIView, size: CGSize, permittedArrowDirections: UIPopoverArrowDirection) {
        let selectionC = SelectionPopover()
        selectionC.options = options
        selectionC.delegate = delegate
        selectionC.tag = tag
        selectionC.view.frame.size = size
        selectionC.preferredContentSize = size
        selectionC.modalPresentationStyle = .Popover
        selectionC.popoverPresentationController!.delegate = selectionC
        selectionC.popoverPresentationController!.sourceRect = sourceRect
        selectionC.popoverPresentationController!.sourceView = sourceView
        selectionC.popoverPresentationController!.permittedArrowDirections = permittedArrowDirections
        
        var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        while((topVC!.presentedViewController) != nil){
            topVC = topVC!.presentedViewController
        }
        topVC!.presentViewController(selectionC, animated: true, completion: nil)
    }

    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // create table view
        tableView = UITableView(frame: view.frame, style: .Plain)
        tableView!.delegate = self
        tableView!.dataSource = self
        tableView!.translatesAutoresizingMaskIntoConstraints = false
        tableView!.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView!)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": tableView!]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": tableView!]))
    }
    
    
    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
        }
        cell!.textLabel!.text = options[indexPath.row]

        return cell!
    }
    
    
    // MARK: - UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.popoverSelectedOption(indexPath.row, tag: tag)
    }
    
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None // to make sure this VC is always presented as popover
    }
}