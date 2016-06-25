//
//  AppLogViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 29-03-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//
//  In a future version we can add error highlighting
//

import UIKit

class AppLogViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var textView: UITextView!
    
    
    // MARK: - Functions
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        view.backgroundColor = UIColor.groupTableViewBackgroundColor()
        textView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        textView.text = console.loadLog()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !textView.text.isEmpty {
            textView.scrollRangeToVisible(NSMakeRange(textView.text.characters.count-1, 1))
        }
    }
    
    
    // MARK: - IBActions

    @IBAction func action(sender: UIBarButtonItem) {
        // display action screens
        let activityViewController = UIActivityViewController(activityItems: [console.fileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        presentViewController(activityViewController, animated: true, completion: nil)
    }
}
