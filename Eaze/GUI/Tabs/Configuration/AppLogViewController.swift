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
        
        // color
        view.backgroundColor = globals.colorTableBackground
        textView.backgroundColor = globals.colorTableBackground
        
        // set text
        textView.text = console.loadLog()
        
        // scroll to bottom
        /*if !textView.text.isEmpty {
            let offset = CGPoint(x: 0, y: textView.contentSize.height - textView.bounds.height)
            textView.setContentOffset(offset, animated: false)
            //textView.scrollRangeToVisible(NSMakeRange(textView.text.characters.count-1, 1))
        }*/
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !textView.text.isEmpty {
            //let offset = CGPoint(x: 0, y: textView.contentSize.height - textView.bounds.height)
            //textView.setContentOffset(offset, animated: false)
            textView.scrollRangeToVisible(NSMakeRange(textView.text.characters.count-1, 1))
        }
    }
    
    
    // MARK: - IBActions

    @IBAction func action(sender: UIBarButtonItem) {
        console.halveLog()
        /*
        // display action screens
        let activityViewController = UIActivityViewController(activityItems: [console.fileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        presentViewController(activityViewController, animated: true, completion: nil)*/
    }
}
