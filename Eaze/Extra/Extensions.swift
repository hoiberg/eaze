//
//  Extensions.swift
//  CleanflightMobile
//
//  Created by Alex on 23-12-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

// MARK: - String

extension String {
    var floatValue: Float {
        return NSString(string: self).floatValue
    }
    
    var doubleValue: Double {
        return NSString(string: self).doubleValue
    }
    
    var intValue: Int {
        return NSString(string: self).integerValue
    }
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(startIndex.advancedBy(r.startIndex) ..< startIndex.advancedBy(r.endIndex))
    }
    
    public func indexOfCharacter(char: Character) -> Int? {
        if let idx = characters.indexOf(char) {
            return startIndex.distanceTo(idx)
        }
        return nil
    }
}


// MARK: - Array

extension RangeReplaceableCollectionType where Generator.Element: Equatable {
    /// Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object: Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    /// For each given object: Remove first collection element that is equal to the given `object`:
    mutating func removeObjects(objects: [Generator.Element]) {
        for object in objects {
            if let index = self.indexOf(object) {
                self.removeAtIndex(index)
            }
        }
    }
    
    /// Append to this array only if it does not already exist in it
    mutating func appendIfNonexistent(object: Generator.Element) {
        if !contains(object) {
            append(object)
        }
    }
}

extension CollectionType {
    /// Returns the object that conforms to the predicate, or nil if it does not find any
    func find(@noescape predicate: (Self.Generator.Element) throws -> Bool) rethrows -> Self.Generator.Element? {
        return try indexOf(predicate).map({self[$0]})
    }
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


// MARK: - NSDate

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs === rhs || lhs.compare(rhs) == .OrderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == .OrderedAscending
}

extension NSDate: Comparable { }


// MARK: - UIDevice

extension UIDevice {
    class var isPad: Bool {
        return currentDevice().userInterfaceIdiom == .Pad
    }
    
    class var isPhone: Bool {
        return currentDevice().userInterfaceIdiom == .Phone
    }
}


// MARK: - UIViewController

extension UIViewController {
    /// Returns whether this view controller is currently being shown to the user
    var isBeingShown: Bool {
        get {
            return isViewLoaded() && view.window != nil
        }
    }
}


// MARK: - UIImage

extension UIImageView {
    /// Sets the color of all non-transparent pixels of the current image
    func tint(color: UIColor) {
        tintColor = color
        image = image?.imageWithRenderingMode(.AlwaysOriginal)
    }
}


// MAKR: - UIButton

extension UIButton {
    func setBackgroundColor(color: UIColor, forState state: UIControlState) {
        let colorView = UIView(frame: self.frame)
        colorView.backgroundColor = color
        
        UIGraphicsBeginImageContext(colorView.bounds.size)
        colorView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, forState: state)
    }
}


// MARK: - UIColor

extension UIColor {
    /// Takes integers ranging 0-255
    convenience init(withRange255Red red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    /// Takes integers ranging 0-255
    convenience init(withRange255Red red: Int, green: Int, blue: Int, alpha: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        assert(alpha >= 0 && alpha <= 255, "Invalid alpha compontent")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha) / 255.0)
    }
    
    /// Takes hex values like 0x4BC218 and converts them to an UIColor object
    convenience init(hex: Int) {
        self.init(withRange255Red:(hex >> 16) & 0xFF, green:(hex >> 8) & 0xFF, blue:hex & 0xFF)
    }
    
    /// Takes hex values with alpha like 0x42BC8AFF and converts them to an UIColor object
    convenience init(hexWithAlpha hex: Int) {
        self.init(withRange255Red:(hex >> 24) & 0xFF, green:(hex >> 16) & 0xFF, blue:(hex >> 8) & 0xFF, alpha:hex & 0xFF)
    }
}