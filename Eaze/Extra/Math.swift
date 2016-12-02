//
//  Math.swift
//  CleanflightMobile
//
//  Created by Alex on 23-12-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import Foundation

postfix public func ++(x: inout Int) -> Int {
    x += 1
    return x - 1
}

prefix public func --(x: inout Int) -> Int {
    x -= 1
    return x
}

/// Returns an UNSINED Integer composed of two UInt8's out of the given array at the given offset.
/// Assumes big endian notation.
func getUInt16(_ arr: [UInt8], offset: Int) -> UInt16 {
    var newInt: UInt16 = 0
    newInt |= UInt16(arr[offset+1]) << 8
    newInt |= UInt16(arr[offset])
    return newInt
}

/// Returns an UNSIGNED Integer composed of four UInt8's out of the given array at the given offset.
/// Assumes big endian notation
func getUInt32(_ arr: [UInt8], offset: Int) -> UInt32 {
    var newInt: UInt32 = 0
    newInt |= UInt32(arr[offset+3]) << 24
    newInt |= UInt32(arr[offset+2]) << 16
    newInt |= UInt32(arr[offset+1]) << 8
    newInt |= UInt32(arr[offset])
    return newInt
}

/// Returns an SIGNED Integer composed of one Int8's out of the given array at the given offset.
/// Assumes big endian notation
func getInt8(_ arr: [UInt8], offset: Int) -> Int8 {
    return Int8(bitPattern: arr[offset])
}

/// Returns an SIGNED Integer composed of two UInt8's out of the given array at the given offset.
/// Assumes big endian notation
func getInt16(_ arr: [UInt8], offset: Int) -> Int16 {
    var newInt: Int16 = 0
    newInt |= Int16(bitPattern: UInt16(arr[offset+1])) << 8
    newInt |= Int16(bitPattern: UInt16(arr[offset]))
    return newInt
}

/// Returns an SIGNED Integer composed of four UInt8's out of the given array at the given offset.
/// Assumes big endian notation
func getInt32(_ arr: [UInt8], offset: Int) -> Int32 {
    var newInt: Int32 = 0
    newInt |= Int32(bitPattern: UInt32(arr[offset+3])) << 24
    newInt |= Int32(bitPattern: UInt32(arr[offset+2])) << 16
    newInt |= Int32(bitPattern: UInt32(arr[offset+1])) << 8
    newInt |= Int32(bitPattern: UInt32(arr[offset]))
    return newInt
}

extension Float {
    func stringWithDecimals(_ a: Int) -> String {
        let astring = ".\(a)"
        return String(NSString(format: "%\(astring)f" as NSString, self))
    }
    
    func roundWithDecimals(_ decimals: Int) -> Float {
        let factor = powf(Float(10), Float(decimals))
        return (self * factor).rounded() / factor
    }
}

extension Double {
    func stringWithDecimals(_ a: Int) -> String {
        let astring = ".\(a)"
        return String(NSString(format: "%\(astring)f" as NSString, self))
    }
    
    func roundWithDecimals(_ decimals: Int) -> Double {
        let factor = pow(10.0, Double(decimals))
        return (self * factor).rounded() / factor
    }
}

extension Int {
    var lowByte: UInt8 {
        return UInt8(self & 0xFF)
    }
    
    var highByte: UInt8 {
        return UInt8((self >> 8) & 0xFF)
    }
    
    /// Returns the Nth byte of this integer (0 = least significant byte)
    func specificByte(_ byte: Int) -> UInt8 {
        return UInt8((self >> (8 * byte)) & 0xFF)
    }
    
    public func bitCheck(_ bit: Int) -> Bool {
        return (self & (1 << bit)) != 0
    }
    
    public mutating func setBit(_ bit: Int, value: Int) {
        self ^= (-value ^ self) & (0b1 << bit)
    }
}

extension Int16 {
    var lowByte: UInt8 {
        return UInt8(UInt16(bitPattern: self) & 0xFF)
    }
    
    var highByte: UInt8 {
        return UInt8(UInt16(bitPattern: self) >> 8)
    }
    
    /// Returns the Nth byte of this integer (0 = least significant byte)
    func specificByte(_ byte: Int) -> UInt8 {
        return UInt8((UInt16(bitPattern: self) >> UInt16(8 * byte)) & 0xFF)
    }
    

}

extension UInt16 {
    var lowByte: UInt8 {
        return UInt8(self & 0xFF)
    }
    
    var highByte: UInt8 {
        return UInt8(self >> 8)
    }
    
    /// Returns the Nth byte of this integer (0 = least significant byte)
    func specificByte(_ byte: Int) -> UInt8 {
        return UInt8((self >> UInt16(8 * byte)) & 0xFF)
    }
}

extension Int32 {
    /// Returns the Nth byte of this integer (0 = least significant byte)
    func specificByte(_ byte: Int) -> UInt8 {
        return UInt8((UInt32(bitPattern: self) >> UInt32(8 * byte)) & 0xFF)
    }
}

extension UInt32 {
    /// Returns the Nth byte of this integer (0 = least significant byte)
    func specificByte(_ byte: Int) -> UInt8 {
        return UInt8((self >> UInt32(8 * byte)) & 0xFF)
    }
}
