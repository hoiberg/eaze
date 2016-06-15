//
//  SelectionTableViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 23-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

protocol SelectionTableViewControllerDelegate {
    func selectionTableWithTag(tag: Int, didSelectItem item: Int)
}

class SelectionTableViewController: GroupedTableViewController {
    
    var delegate: SelectionTableViewControllerDelegate?
    var tag = 0
    var items: [String] = []
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        tableView!.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        if UIDevice.isPad { tableView.separatorStyle = .None }
    }

    
    // MARK: - TableView data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
        }
        cell!.textLabel!.text = items[indexPath.row]

        return cell!
    }
    
    
    // MARK: - TableView delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.selectionTableWithTag(tag, didSelectItem: indexPath.row)
        navigationController?.popViewControllerAnimated(true)
    }
}