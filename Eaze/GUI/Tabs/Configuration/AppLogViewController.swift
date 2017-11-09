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
    
    
    // MARK: - Variables
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPhone ? .portrait : [.landscapeLeft, .landscapeRight]
    }
    
    
    // MARK: - Functions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.backgroundColor = UIColor.groupTableViewBackground
        textView.backgroundColor = UIColor.groupTableViewBackground
        
        textView.text = console.loadLog()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !textView.text.isEmpty {
            textView.scrollRangeToVisible(NSMakeRange(textView.text.characters.count-1, 1))
        }
    }
    
    
    // MARK: - IBActions

    @IBAction func action(_ sender: UIBarButtonItem) {
        // display action screens
        let activityViewController = UIActivityViewController(activityItems: [console.fileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
}
