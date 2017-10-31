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
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String { // TODO: To be tested!!
        return self[r.lowerBound ..< r.upperBound]
        // substring(with: characters.index(startIndex, offsetBy: r.lowerBound) ..< characters.index(startIndex, offsetBy: r.upperBound))
    }
    
    public func indexOfCharacter(_ char: Character) -> Int? {
        if let idx = characters.index(of: char) {
            return characters.distance(from: startIndex, to: idx)
        }
        return nil
    }
}


// MARK: - Arrays

extension RangeReplaceableCollection where Iterator.Element: Equatable {
    /// Remove first collection element that is equal to the given `object`:
    mutating func removeObject(_ object: Iterator.Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
    
    /// For each given object: Remove first collection element that is equal to the given `object`:
    mutating func removeObjects(_ objects: [Iterator.Element]) {
        for object in objects {
            if let index = self.index(of: object) {
                self.remove(at: index)
            }
        }
    }
    
    /// Append to this array only if it does not already exist in it
    mutating func appendIfNonexistent(_ object: Iterator.Element) {
        if !contains(object) {
            append(object)
        }
    }
}

extension Collection {
    /// Returns the object that conforms to the predicate, or nil if it does not find any
    func find(_ predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> Self.Iterator.Element? {
        return try index(where: predicate).map({self[$0]})
    }

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Equatable {
    /// Returns a copy of the array with the given element removed
    func arrayByRemovingObject(_ object: Element) -> [Element] {
        var new = self
        if let index = new.index(where: { $0 == object }) {
            new.remove(at: index)
        }
        return new
    }
}

extension Array where Element: Copyable {
    func deepCopy() -> [Element] {
        return map { Element.init(copy: $0) }
    }
}


// MARK: - NSData

extension Data {
    func getBytes() -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count / MemoryLayout<UInt8>.size)
        copyBytes(to: &bytes, count: count)
        return bytes
    }
}


// MARK: - UIDevice

extension UIDevice {
    class var isPad: Bool {
        return current.userInterfaceIdiom == .pad
    }
    
    class var isPhone: Bool {
        return current.userInterfaceIdiom == .phone
    }
    
    class var platform: String {
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return NSString(bytes: &sysinfo.machine, length: Int(_SYS_NAMELEN), encoding: String.Encoding.ascii.rawValue)! as String
    }
}


// MARK: - UIViewController

extension UIViewController {
    /// Returns whether this view controller is currently being shown to the user
    var isBeingShown: Bool {
        return isViewLoaded && view.window != nil
    }
}


// MARK: - UIImage

extension UIImageView {
    /// Sets the color of all non-transparent pixels of the current image
    func tint(_ color: UIColor) {
        tintColor = color
        image = image?.withRenderingMode(.alwaysTemplate)
    }
}


// MAKR: - UIButton

extension UIButton {
    
    static fileprivate let minimumHitArea = CGSize(width: 44, height: 44)
    
    func setBackgroundColor(_ color: UIColor, forState state: UIControlState) {
        let colorView = UIView(frame: self.frame)
        colorView.backgroundColor = color
        
        UIGraphicsBeginImageContext(colorView.bounds.size)
        colorView.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: state)
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // if the button is hidden/disabled/transparent it can't be hit
        if self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.01 { return nil }
        
        // increase the hit frame to be at least as big as `minimumHitArea`
        let buttonSize = self.bounds.size,
            widthToAdd = max(UIButton.minimumHitArea.width - buttonSize.width, 0),
            heightToAdd = max(UIButton.minimumHitArea.height - buttonSize.height, 0),
            largerFrame = self.bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)
        
        // perform hit test on larger frame
        return (largerFrame.contains(point)) ? self : nil
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
    
    class func cleanflightGreen() -> UIColor {
        return UIColor(red: 72/255, green: 160/255, blue: 23/255, alpha: 1.0)
    }
}


// MARK: - Ints
// Often, doubles will be 1.999999997 instead of 2 - which will result in an
// Int being 1 instead of 2 (as it always rounds down). This caused bugs with
// the tuning fields. So to fix the problem, here are some overrides.

extension UInt8 {
    init(_ other: Double) {
        self.init(Int(round(other)))
    }
}

extension Int8 {
    init(_ other: Double) {
        self.init(Int(round(other)))
    }
}

extension UInt16 {
    init(_ other: Double) {
        self.init(Int(round(other)))
    }
}

extension Int16 {
    init(_ other: Double) {
        self.init(Int(round(other)))
    }
}

extension UInt32 {
    init(_ other: Double) {
        self.init(Int(round(other)))
    }
}

extension Int32 {
    init(_ other: Double) {
        self.init(Int(round(other)))
    }
}
