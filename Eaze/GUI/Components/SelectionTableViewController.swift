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

final class SelectionTableViewController: GroupedTableViewController {
    
    var delegate: SelectionTableViewControllerDelegate?,
        tag = 0,
        items: [String] = []
    

    // MARK: - Functions
    
    override func viewDidLoad() {
        tableView!.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        if UIDevice.isPad { tableView.separatorStyle = .None }
    }

    
    // MARK: - TableViewDataSource

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
    
    
    // MARK: - TableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.selectionTableWithTag(tag, didSelectItem: indexPath.row)
        navigationController?.popViewControllerAnimated(true)
    }
}