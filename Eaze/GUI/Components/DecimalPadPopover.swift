//
//  DecimalPadPopoverViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 19-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

protocol DecimalPadPopoverDelegate {
    func updateText(newText: String)
    func decimalPadWillDismiss()
}

final class DecimalPadPopover: UIViewController {
    
    // MARK: - IBOutlets

    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var textField: UITextField!
    
    
    // MARK: - Class Variables
    
    private static var isLoading = false
    
    
    // MAKR: - Variables
    
    var delegate: DecimalPadPopoverDelegate?
    private let chars = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "b"]
    
    
    // MARK: - Class Functions
    
    class func presentWithDelegate(delegate: DecimalPadPopoverDelegate, text: String, sourceRect: CGRect, sourceView: UIView, size: CGSize, permittedArrowDirections: UIPopoverArrowDirection) {
        guard !isLoading else { return }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let popover = DecimalPadPopover()
            popover.delegate = delegate
            popover.view.frame.size = size
            popover.preferredContentSize = size
            popover.modalPresentationStyle = .Popover
            popover.popoverPresentationController!.sourceRect = sourceRect
            popover.popoverPresentationController!.sourceView = sourceView
            popover.popoverPresentationController!.permittedArrowDirections = permittedArrowDirections
            
            var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
            while((topVC!.presentedViewController) != nil){
                topVC = topVC!.presentedViewController
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                topVC!.presentViewController(popover, animated: true, completion: nil)
                popover.textField.text = text
                isLoading = false
            }
        }
    }
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.inputView = UIView() // to make sure no keyboard is shown
        textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.decimalPadWillDismiss()
    }
    
    
    // MARK: - IBActions

    @IBAction func buttonAction(sender: UIButton) {
        if sender.tag == 11 {
            textField.deleteBackward()
        } else {
            textField.insertText(chars[sender.tag])
        }
        delegate?.updateText(textField.text!)
    }
}