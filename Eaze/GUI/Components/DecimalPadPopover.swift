//
//  DecimalPadPopoverViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 19-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

protocol DecimalPadPopoverDelegate {
    func updateText(_ newText: String)
    func decimalPadWillDismiss()
}

final class DecimalPadPopover: UIViewController {
    
    // MARK: - IBOutlets

    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var textField: UITextField!
    
    
    // MARK: - Class Variables
    
    fileprivate static var isLoading = false
    
    
    // MAKR: - Variables
    
    var delegate: DecimalPadPopoverDelegate?
    fileprivate let chars = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "b"]
    
    
    // MARK: - Class Functions
    
    class func presentWithDelegate(_ delegate: DecimalPadPopoverDelegate, text: String, sourceRect: CGRect, sourceView: UIView, size: CGSize, permittedArrowDirections: UIPopoverArrowDirection) {
        guard !isLoading else { return }
        DispatchQueue(label: "nl.hangar42.eaze.createPopover").async {
            let popover = DecimalPadPopover()
            popover.delegate = delegate
            popover.view.frame.size = size
            popover.preferredContentSize = size
            popover.modalPresentationStyle = .popover
            popover.popoverPresentationController!.sourceRect = sourceRect
            popover.popoverPresentationController!.sourceView = sourceView
            popover.popoverPresentationController!.permittedArrowDirections = permittedArrowDirections
            
            var topVC = UIApplication.shared.keyWindow?.rootViewController
            while((topVC!.presentedViewController) != nil){
                topVC = topVC!.presentedViewController
            }
            
            DispatchQueue.main.async {
                topVC!.present(popover, animated: true, completion: nil)
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.decimalPadWillDismiss()
    }
    
    
    // MARK: - IBActions

    @IBAction func buttonAction(_ sender: UIButton) {
        if sender.tag == 11 {
            textField.deleteBackward()
        } else {
            textField.insertText(chars[sender.tag])
        }
        delegate?.updateText(textField.text!)
    }
}
