// =====================================================================================================================
//
//  *** Cleanflightmobile edit ***
//  save() on line 1136 has been edited to return a NSError? instead of a bool.
//
//
//  File:       VJson.swift
//  Project:    SwifterJSON
//
//  Version:    0.9.3
//
//  Author:     Marinus van der Lugt
//  Website:    http://www.balancingrock.nl/swifterjson
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/SwifterJSON
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
//
//  License:    Use or redistribute this code any way you like with the following two provision:
//
//  1) You ACCEPT this source code AS IS without any guarantees that it will work as intended. Any liability from its
//  use is YOURS.
//
//  2) You WILL NOT seek damages from the author or balancingrock.nl.
//
//  I also ask you to please leave this header with the source code.
//
//  I strongly believe that NAP is the way for societies to function optimally. I thus reject the implicit use of force
//  to extract payment. Since I cannot negotiate with you about the price of this code, I have choosen to leave it up to
//  you to determine its price. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
//
//  This JSON implementation was written using the definitions as found on: http://json.org (2015.01.01)
//
// =====================================================================================================================
//
// This JSON class/parser was developped as a faster alternative to SwifterJSON.
//
// Subscript accessors are implemented, i.e. it is possible to address values as:
// let title = jsonHierarchy["top"]["book"][3]["title"].string
// But this simplicity comes at a double cost:
// 1) Accessing any VJson object with a subscript will turn that object into either an .ARRAY or .OBJECT depending on
//    the kind of subscript used.
// 2) VJson objects will automatically be created as needed to fulfill the path given by the subscripts. For integer
//    subscripts missing subscript indicies will be filled by .NULL objects. Note: If subsequent manipulations creates
//    auto generated objects that no longer serve a purpose, then these purposeless objects will not be saved nor appear
//    in a description.
//    Example:
//        let jsonHierarchy = VJson.createJsonHierarchy()
//        let title = VJson.createString(value: "Once upon a time", name: nil)
//        jsonHierarchy["books"][1] = title
//        print(jsonHierarchy.code) // prints {"books":[null,"Once upon a time"]}
//        jsonHierarchy["books"].removeChild(title)
//        print(jsonHierarchy.code) // prints {"top":[]}
//
// By far the best way to use a JSON hierarchy is to create one using the createJsonHierarchy calls and do all
// subsequent accessing with the subscript operators. While it is possible to do everything manually I find that it is
// very easy to make mistakes that way.
//
// To make the subscript accessors work, it was necessary to create an automaticaly generated array at the top level
// if the first subscript is an integer. That array will have the name "array".
// Example:
//
// =====================================================================================================================
//
// History
// v0.9.3 - Updated for changes in ASCII.swift
// v0.9.2 - Fixed a problem where an assigned NULL object was removed from the hierarchy
// v0.9.1 - Changed parameter to 'addChild' to an optional.
//        - Fixed a problem where an object without a leading brace in an array would not be thrown as an error
//        - Changed 'makeCopy()' to 'copy' for constency with other projects
//        - Fixed the asString for BOOL types
//        - Changed all "...Value" returns to optionals (makes more sense as this allows the use of guard let statements
//        to check the JSON structure.
//        - Overhauled the child support interfaces (changes parameters and return values to optionals)
//        - Removed 'set' access from arrayValue and dictionaryValue as it could potentially lead to an invalid JSON
//        hierarchy
//        - Fixed subscript accessors, array can now be used on top-level with an implicit name of "array"
//        - Fixed missing braces around named objects in an array
// v0.9.0 Initial release
// =====================================================================================================================


import Foundation

func == (lhs: VJson, rhs: VJson) -> Bool {
    if lhs.type != rhs.type { return false }
    if lhs.bool != rhs.bool { return false }
    if lhs.number != rhs.number { return false }
    if lhs.string != rhs.string { return false }
    if lhs.name != rhs.name { return false }
    if (lhs.children == nil) && (rhs.children != nil) { return false }
    if (lhs.children != nil) && (rhs.children == nil) { return false }
    if (lhs.children == nil) && (rhs.children == nil) { return true }
    if lhs.children!.count != rhs.children!.count { return false }
    for i in 0 ..< lhs.children!.count {
        let lhc = lhs.children![i]
        let rhc = rhs.children![i]
        if lhc != rhc { return false }
    }
    return true
}


/**
 This class implements the JSON specification.
 */

final class VJson: Equatable, CustomStringConvertible, SequenceType {
    
    
    /// The error type that gets thrown if errors are found during parsing.
    
    enum Exception: ErrorType, CustomStringConvertible {
        case REASON(code: Int, incomplete: Bool, message: String)
        var description: String {
            if case let .REASON(code, incomplete, message) = self { return "[\(code), Incomplete:\(incomplete)] \(message)" }
            return "VJson: Error in Exception enum"
        }
    }
    
    
    // =================================================================================================================
    // MARK: - type
    
    /// The JSON types.
    
    enum JType { case NULL, BOOL, NUMBER, STRING, OBJECT, ARRAY }
    
    
    /// The JSON type of this object.
    
    private var type: JType
    
    
    /// - Returns: True if this object contains a JSON NULL object.
    
    var isNull: Bool { return self.type == JType.NULL }
    
    
    /// - Returns: True if this object contains a JSON BOOL object.
    
    var isBool: Bool { return self.type == JType.BOOL }
    
    
    /// - Returns: True if this object contains a JSON NUMBER object.
    
    var isNumber: Bool { return self.type == JType.NUMBER }
    
    
    /// - Returns: True if this object contains a JSON STRING object.
    
    var isString: Bool { return self.type == JType.STRING }
    
    
    /// - Returns: True if this object contains a JSON ARRAY object.
    
    var isArray: Bool { return self.type == JType.ARRAY }
    
    
    /// - Returns: True if this object contains a JSON OBJECT object.
    
    var isObject: Bool { return self.type == JType.OBJECT }
    
    
    // =================================================================================================================
    // MARK: - name
    
    // The name of this object if it is part of a name/value pair.
    
    private var name: String?
    
    /// - Parameter newValue: The new name for this object. If this object did not have a name, it will turn this object into a name/value pair.
    /// - Returns: The name part of a name/value pair. Nil if this object does not have a name.
    
    var nameValue: String? {
        get {
            return name
        }
        set {
            name = newValue
        }
    }
    
    /// - Returns: True if this object is a name/value pair. False otherwise.
    
    var hasName: Bool { return name != nil }
    
    
    /// Removes the name component of a name/value pair. Effectively turns this object into an array element.
    
    func removeName() { name = nil }
    
    
    // =================================================================================================================
    // MARK: - null
    
    /// - Parameter newValue: Writing (i.e. true or false) will always convert this value into a JSON NULL if it was not. If it was of a different type, old information will be discarded.
    /// - Returns: True if this is a JSON NULL item, nil otherwise.
    
    var nullValue: Bool? {
        get {
            if type == .NULL {
                return true
            } else {
                return nil
            }
        }
        set {
            if !isNull {
                neutralize()
                type = .NULL
            }
            createdBySubscript = false // A previous null may have been created by a subscript accessor, this prevents it from being removed.
        }
    }
    
    /// - Returns: True if the type of this object is .NULL, false in all other cases.
    
    var asNull: Bool { return type == .NULL }
    
    
    // =================================================================================================================
    // MARK: - bool
    
    // The value if this is a .BOOL JSON value.
    
    private var bool: Bool?
    
    
    /// - Parameter newValue: The new bool value of this JSON item. Note that it will also convert this object into a JSON BOOL if it was of a different type, discarding old information in the process (if any)
    /// - Returns: The bool value of this object if the object is a JSON BOOL. Nil if this object is not a JSON BOOL item.
    
    var boolValue: Bool? {
        get {
            return bool
        }
        set {
            if type != .BOOL {
                neutralize()
                type = .BOOL
            }
            bool = newValue
        }
    }
    
    
    /// - Returns: The bool value of this object if the object is a JSON BOOL. Otherwise it will try to interpret the value as a bool e.g. a NULL will be false, a NUMBER 1(.0) = true, other numbers are false, STRING "true" equals true, all other strings equal false. ARRAY and OBJECT both equal false.
    
    var asBool: Bool {
        switch type {
        case .NULL: return false
        case .BOOL: return bool!
        case .NUMBER: return number!.boolValue ?? false
        case .STRING: return string! == "true"
        case .OBJECT: return false
        case .ARRAY: return false
        }
    }
    
    
    // =================================================================================================================
    // MARK: - number
    
    // The value if this is a .NUMBER JSON value.
    
    private var number: NSNumber?
    
    
    /// - Parameter newValue: The doubleValue of this NSNumber will be used to create a new NSNumber for this JSON item. Note that it will also convert this object into a JSON NUMBER if it was of a different type. Discarding old information in the process (if any)
    /// - Returns: A NSNumber copy of the doubleValue of the NSNumber in this object if this object is a JSON NUMBER. Nil otherwise.
    
    var numberValue: NSNumber? {
        get {
            if number == nil { return nil }
            return NSNumber(double: number!.doubleValue) // Make sure to return a copy
        }
        set {
            if type != .NUMBER {
                neutralize()
                type = .NUMBER
            }
            if newValue == nil { number = nil }
            number = NSNumber(double: newValue!.doubleValue)
        }
    }
    
    
    /// - Returns: Attempts to interpret the value of this object as a number and then creates a new NSNumber with that value. For a NUMBER it returns a copy of that number, for NULL, OBJECT and ARRAY it returns a NSNumber with the value 0, for STRING it tries to read the string as a number (if that fails, it is regarded as a zero) and for a BOOL it creates a NSNumber with the bool as its value.
    
    var asNumber: NSNumber {
        switch type {
        case .NULL, .OBJECT, .ARRAY: return NSNumber(int: 0)
        case .BOOL: return NSNumber(bool: self.bool!)
        case .NUMBER: return number!.copy() as! NSNumber
        case .STRING: return NSNumber(double: (string! as NSString).doubleValue)
        }
    }
    
    
    /// - Parameter newValue: The value of this int will be used to create a new NSNumber for this JSON item. Note that it will also convert this object into a JSON NUMBER if it was of a different type, discarding old information in the process (if any)
    /// - Returns: A NSNumber copy of the integerValue of the NSNumber in this object if this object is a JSON NUMBER. Otherwise a value of zero.
    
    var integerValue: Int? {
        get {
            if number == nil { return nil }
            return number!.integerValue
        }
        set {
            if type != .NUMBER {
                neutralize()
                type = .NUMBER
            }
            if newValue == nil { number = nil }
            number = NSNumber(integer: newValue!)
        }
    }
    
    
    /// - Returns: Attempts to interpret the value of this object as a number and returns its integerValue. For a NUMBER it returns its integer value, for NULL, OBJECT and ARRAY it returns the value 0, for STRING it tries to read the string as a number (if that fails, it is regarded as a zero) and return its integer value and for a BOOL it creates a NSNumber with the bool as its value and returns the integer value of it.
    
    var asInt: Int {
        return asNumber.integerValue
    }
    
    
    /// - Parameter newValue: The value of this double will be used to create a new NSNumber for this JSON item. Note that it will also convert this object into a JSON NUMBER if it was of a different type, discarding old information in the process (if any)
    /// - Returns: A NSNumber with the value of the doubleValue of the NSNumber in this object if this object is a JSON NUMBER. Otherwise a NSNumber with a value of zero.
    
    var doubleValue: Double? {
        get {
            if number == nil { return nil }
            return number!.doubleValue
        }
        set {
            if type != .NUMBER {
                neutralize()
                type = .NUMBER
            }
            if newValue == nil { number = nil }
            number = NSNumber(double: newValue!)
        }
    }
    
    
    /// - Returns: Attempts to interpret the value of this object as a number and returns its doubleValue. For a NUMBER it returns its double value, for NULL, OBJECT and ARRAY it returns the value 0.0, for STRING it tries to read the string as a number (if that fails, it is regarded as a zero) and return its double value and for a BOOL it creates a NSNumber with the bool as its value and returns the double value of it.
    
    var asDouble: Double {
        return asNumber.doubleValue
    }
    
    
    // =================================================================================================================
    // MARK: - string
    
    // The value if this is a .STRING JSON value.
    
    private var string: String?
    
    /// - Parameter newValue: The value that will be used to update the string of this JSON item. Note that it will also convert this object into a JSON STRING if it was of a different type, discarding old information in the process (if any). If the newValue contains any double-quotes, these will be escaped.
    /// - Returns: A string value of this object if this object is a JSON STRING. If the JSON string contained escaped quotes, these escaped sequences will be replaced by a normal double quote. Otherwise nil.
    
    var stringValue: String? {
        get {
            if string == nil { return nil }
            return self.string!.stringByReplacingOccurrencesOfString("\\\"", withString: "\"")
        }
        set {
            if type != .STRING {
                neutralize()
                type = .STRING
            }
            if newValue == nil { string = nil }
            string = newValue!.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        }
    }
    
    /// - Returns: Attempts to interpret the value of this object as a string and returns it. NUMBER and BOOL return their string representation. NULL it returns "null" for OBJECT and ARRAY it returns an empty string.
    
    var asString: String {
        switch type {
        case .NULL: return "null"
        case .BOOL: return "\(bool!)"
        case .STRING: return string!
        case .NUMBER: return number!.stringValue
        case .ARRAY, .OBJECT: return ""
        }
    }
    
    
    
    // =================================================================================================================
    // MARK: - array/object
    
    // Contains the child elements, be they array elements of name/value pairs.
    
    private var children: Array<VJson>?
    
    
    /// - Returns: True if this object contains any childeren, either ARRAY items or OBJECT items. False if this object does not have any children.
    
    var hasChildren: Bool {
        if children == nil { return false }
        return children!.count > 0
    }
    
    
    /// - Returns: The number of child objects this object contains. Always returns 0 if this object is neither an OBJECT or an ARRAY.
    
    var nofChildren: Int {
        if !hasChildren { return 0 }
        return children!.count
    }
    
    
    /// - Parameter newValue: Copies of the content of this array will replace the existing children.
    /// - Returns: An array containing a copy of all children if this is an ARRAY or OBJECT item. For all other types it returns an empty array.
    
    var arrayValue: Array<VJson>? {
        guard type == .ARRAY || type == .OBJECT else { return nil }
        var arr: Array<VJson> = []
        for child in children! {
            arr.append(child.copy)
        }
        return arr
    }
    
    
    /// - Parameter newValue: Copies of the content of this dictionary will replace the existing children.
    /// - Returns: A dictionary containing a copy of all children if this is an OBJECT item. For all other types it returns an empty array.
    
    var dictionaryValue: Dictionary<String, VJson>? {
        if type != .OBJECT { return nil }
        var dict: Dictionary<String, VJson> = [:]
        for child in children! {
            dict[child.name!] = child.copy
        }
        return dict
    }
    
    
    // If this object was created to fullfill a subscript access, this property is set to 'true'. It is false for all other objects.
    
    private var createdBySubscript: Bool = false
    
    
    private func neutralize() {
        children = nil
        createdBySubscript = false
        bool = nil
        number = nil
        string = nil
    }
    
    
    // MARK: - Child access/management
    
    /**
    Inserts the given child at the given index.
    - Note: If the child is insertend in an OBJECT, it must have a name. If it is inserted into an array is must not have a name.
    - Parameter child: The VJson object to be inserted.
    - Parameter atIndex: The index t which it will be inserted. Must be < nofChildren to succeed.
    - Returns: True if the operation succeeded, false if not. Nil if the child is nil.
    */
    
    func insertChild(child: VJson?, atIndex index: Int) -> Bool? {
        
        guard let c = child else { return nil }
        guard children != nil else { return false }
        guard index < nofChildren else { return false }
        guard (type == .OBJECT) ? (c.name != nil) : true else { return false }
        guard (type == .ARRAY) ? (c.name == nil) : true else { return false }
        
        children!.insert(c, atIndex: index)
        
        return true
    }
    
    
    /**
     Appends the given object to the end of the current children.
     - Note: Only for ARRAY objects.
     - Parameter child: The VJson object to be inserted.
     - Returns: True if the operation succeeded, false if not. Nil if the child is nil.
     */
    
    func appendChild(child: VJson?) -> Bool? {
        
        guard let c = child else { return nil }
        guard children != nil else { return false }
        guard type == .ARRAY else { return false }
        guard (c.type == .OBJECT) ? true : (c.name == nil) else { return false }
        
        children!.append(c)
        
        return true
    }
    
    
    /**
     Replaces the child at the given index with the given child.
     - Note: If the child is insertend in an OBJECT, it must have a name. If it is inserted into an array is must not have a name.
     - Parameter child: The VJson object to be inserted.
     - Returns: True if the operation succeeded, false if not. Nil if the child is nil.
     */
    
    func replaceChild(child: VJson?, atIndex index: Int) -> Bool? {
        
        guard let c = child else { return nil }
        guard children != nil else { return false }
        guard index < nofChildren else { return false }
        guard (type == .OBJECT) ? (c.name != nil) : true else { return false }
        guard (type == .ARRAY) ? (c.name == nil) : true else { return false }
        
        children![index] = c
        
        return true
    }
    
    
    /// - Returns the index of the first child with identical contents as the given child. Nil if no comparable child is found.
    
    func indexOfChild(child: VJson?) -> Int? {
        
        guard let c = child else { return nil }
        guard children != nil else { return nil }
        
        for (index, ownChild) in children!.enumerate() {
            if ownChild === c { return index }
            if ownChild == c { return index }
        }
        
        return nil
    }
    
    
    /// Removes the first child with identical contents as the given child from the hierarchy.
    /// - Returns: True if a child was removed, false if not, nil if the child is nil.
    
    func removeChild(child: VJson?) -> Bool? {
        
        guard let c = child else { return nil }
        guard children != nil else { return false }
        guard let index = self.indexOfChild(c) else { return false }
        
        children!.removeAtIndex(index)
        
        return true
    }
    
    
    /// Removes all children from this object.
    
    func removeAllChildren() {
        if children != nil { children!.removeAll() }
    }
    
    
    /// Add a new object with the given name or replace a current object with that same name (simulate dictionary access)
    /// - Note: Only for on OBJECT objects.
    
    func addChild(child: VJson?, forName name: String) -> Bool? {
        
        guard let c = child else { return nil }
        guard type == .OBJECT else { return false }
        
        c.name = name
        
        for (index, c) in children!.enumerate() {
            if c.name == name {
                replaceChild(c, atIndex: index)
                return true
            }
        }
        
        children!.append(c)
        
        return true
    }
    
    
    /// Remove the first child with the given name (simulate dictionary access)
    
    func removeChildWithName(name: String) -> Bool {
        
        guard type == .OBJECT else { return false }
        
        for (index, c) in children!.enumerate() {
            if c.name == name {
                children!.removeAtIndex(index)
                return true
            }
        }
        
        return false
    }
    
    
    /// Return the child with the given name, nil if no such child exists.
    
    func childWithName(name: String) -> VJson? {
        
        guard type == .OBJECT else { return nil }
        
        for c in children! {
            if c.name == name { return c }
        }
        
        return nil
    }
    
    
    // MARK: - Sequence and Generator protocol
    
    struct MyGenerator: GeneratorType {
        
        typealias Element = VJson
        
        var toSent = Array<Element>() // The objects to be sent in reverse order
        
        init(source: VJson) {
            switch source.type {
            case .NULL, .STRING, .NUMBER, .BOOL: break
            case .ARRAY, .OBJECT:
                for c in source.children!.reverse() {
                    // Note: c is now a copy of a child, except for the number component (if present). That number will still refer to the original NSNumber, hence we copy that ourselves.
                    if c.type == .NUMBER { c.number = c.asNumber }
                    toSent.append(c)
                }
            }
        }
        
        mutating func next() -> MyGenerator.Element? { return toSent.popLast() }
    }
    
    typealias Generator = MyGenerator
    func generate() -> Generator { return MyGenerator(source: self) }
    
    
    // MARK: - Subscript accessors
    
    subscript(index: Int) -> VJson {
        
        set {
            
            // If this is an ARRAY object, then make sure there are enough elements and create the requested element
            
            if type == .ARRAY {
                
                // Ensure that enough elements are present in the array
                
                if index >= children!.count {
                    for _ in children!.count ... index {
                        let newObject = VJson.createNull(name: nil)
                        newObject.createdBySubscript = true
                        children!.append(newObject)
                    }
                }
                
                children![index] = newValue
                
                return
            }
            
            
            // If this is not an ARRAY and not an OBJECT, then turn it into an ARRAY and create the requested element
            
            if type != .OBJECT {
                
                changeToArrayType()
                
                // Ensure that enough elements are present in the array
                
                if index >= children!.count {
                    for _ in children!.count ... index {
                        let newObject = VJson.createNull(name: nil)
                        newObject.createdBySubscript = true
                        children!.append(newObject)
                    }
                }
                
                children![index] = newValue
                
                return
            }
            
            
            // This is an OBJECT without a name, it must be the top level object of the hierarchy.
            // This is in fact invalid, but to allow the use of subscripts at top level we can assume a default array name of "array"
            
            if let existingArray = childWithName("array") {
                
                // It already exists, check if the requested element exists and if not, create it
                
                if index >= existingArray.children!.count {
                    for _ in existingArray.children!.count ... index {
                        let newObject = VJson.createNull(name: nil)
                        newObject.createdBySubscript = true
                        existingArray.children!.append(newObject)
                    }
                }
                
                existingArray.children![index] = newValue
                
                return
                
            } else {
                
                // It does not exist, create one
                
                let newArray = VJson.createArray(name: "array")
                newArray.createdBySubscript = true
                addChild(newArray, forName: "array")
                
                
                // Ensure that enough elements are present in the new array
                
                if index >= newArray.children!.count {
                    for _ in newArray.children!.count ... index {
                        let newObject = VJson.createNull(name: nil)
                        newObject.createdBySubscript = true
                        newArray.children!.append(newObject)
                    }
                }
                
                newArray.children![index] = newValue
                
                return
            }
        }
        
        get {
            
            
            // If this is an ARRAY object, then make sure there are enough elements and return the requested element
            
            if type == .ARRAY {
                
                // Ensure that enough elements are present in the array
                
                if index >= children!.count {
                    for _ in children!.count ... index {
                        let newObject = VJson.createNull(name: nil)
                        newObject.createdBySubscript = true
                        children!.append(newObject)
                    }
                }
                
                return children![index]
            }
            
            
            // If this is not an ARRAY and not an OBJECT, then turn it into an ARRAY and return the requested element
            
            if type != .OBJECT {
                
                changeToArrayType()
                
                // Ensure that enough elements are present in the array
                
                if index >= children!.count {
                    for _ in children!.count ... index {
                        let newObject = VJson.createNull(name: nil)
                        newObject.createdBySubscript = true
                        children!.append(newObject)
                    }
                }
                
                return children![index]
            }
            
            
            // This is an OBJECT without a name, it must be the top level object of the hierarchy.
            // This is in fact invalid, but to allow the use of subscripts at top level we can assume a default array name of "array"
            
            if let existingArray = childWithName("array") {
                
                // It already exists, check if the requested element exists and if not, create it
                
                if index >= existingArray.children!.count {
                    for _ in existingArray.children!.count ... index {
                        let newObject = VJson.createNull(name: nil)
                        newObject.createdBySubscript = true
                        existingArray.children!.append(newObject)
                    }
                }
                
                return existingArray.children![index]
                
            } else {
                
                // It does not exist, create one
                
                let newArray = VJson.createArray(name: "array")
                newArray.createdBySubscript = true
                addChild(newArray, forName: "array")
                
                
                // Ensure that enough elements are present in the new array
                
                if index >= newArray.children!.count {
                    for _ in newArray.children!.count ... index {
                        let newObject = VJson.createNull(name: nil)
                        newObject.createdBySubscript = true
                        newArray.children!.append(newObject)
                    }
                }
                
                return newArray.children![index]
            }
        }
    }
    
    
    // Subscript getter/setter for a JSON OBJECT type.
    
    subscript(key: String) -> VJson {
        
        set {
            
            
            // If this is not an object type, change it into an object
            
            if type != .OBJECT {
                
                changeToObjectType()
            }
            
            addChild(newValue, forName: key)
        }
        
        get {
            
            
            // If this is not an object type, change it into an object
            
            if type != .OBJECT {
                
                changeToObjectType()
            }
            
            
            // If the requested object exist, return it
            
            if let val = childWithName(key) { return val }
            
            
            // If the request value does not exist, create it
            // This allows object creation for 'object["key1"]["key2"]["key3"] = SwifterJSON(12)' constructs.
            
            let newObject = VJson.createNull(name: nil)
            newObject.createdBySubscript = true
            addChild(newObject, forName: key)
            
            return newObject
        }
    }
    
    private func changeToArrayType() {
        neutralize()
        switch type {
        case .OBJECT: type = .ARRAY
        case .ARRAY: break
        case .NULL, .BOOL, .NUMBER, .STRING:
            children = Array<VJson>()
            type = .ARRAY
        }
    }
    
    private func changeToObjectType() {
        neutralize()
        switch type {
        case .ARRAY: type = .OBJECT
        case .OBJECT: break
        case .NULL, .BOOL, .NUMBER, .STRING:
            children = Array<VJson>()
            type = .OBJECT
        }
    }
    
    
    // Returns the object at the given path if it exists and is of the given type.
    
    func objectOfType(type: JType, atPath path: [String]) -> VJson? {
        
        if path.count == 0 {
            
            if self.type == type { return self }
            return nil
            
        } else {
            
            switch self.type {
                
            case .ARRAY:
                
                let i = (path[0] as NSString).integerValue
                
                if i >= self.nofChildren { return nil }
                
                var newPath = path
                newPath.removeFirst()
                
                return children![i].objectOfType(type, atPath: newPath)
                
                
            case .OBJECT:
                
                for child in children! {
                    if child.name == nil { return nil } // Should not be possible
                    if child.name == path[0] {
                        
                        var newPath = path
                        newPath.removeFirst()
                        
                        return child.objectOfType(type, atPath: newPath)
                    }
                }
                return nil
                
                
            default: return nil
            }
        }
    }
    
    func objectOfType(type: JType, atPath path: String ...) -> VJson? {
        return objectOfType(type, atPath: path)
    }
    
    
    // Remove empty objects that resulted from subscript access.
    
    private func removeEmptySubscriptObjects() {
        
        
        // For JSON OBJECTs, remove all name/value pairs that are created by a subscript and do not contain any non-subscript generated value
        
        if type == .OBJECT {
            
            
            // Itterate over all name/value pairs
            
            for child in children! {
                
                
                // Make sure that this value has all its subscript generated values removed
                
                if child.nofChildren > 0 { child.removeEmptySubscriptObjects() }
                
                
                // Remove the value if it is generated by subscript and contains no usefull items
                
                if child.createdBySubscript && child.nofChildren == 0 {
                    self.removeChild(child)
                }
            }
            
            return
        }
        
        
        // For JSON ARRAYs, remove all values that are createdby a subscript and do not contain any non-subscript generated value
        
        if type == .ARRAY {
            
            
            // This array will contain the indicies of all values that should be removed
            
            var itemsToBeRemoved = [Int]()
            
            
            // Loop over all values, backwards. As soon as a value is hit that cannot be removed, stop iterating
            
            if children!.count > 0 {
                
                for index in (0 ..< children!.count).reverse() {
                    
                    let child = children![index]
                    
                    
                    // Make sure that this value has all its subscript generated values removed
                    
                    if child.nofChildren > 0 { child.removeEmptySubscriptObjects() }
                    
                    
                    // If this value is created by subscript, then check if it has content
                    
                    if child.createdBySubscript && child.nofChildren == 0 {
                        itemsToBeRemoved.append(index)
                    } else {
                        break
                    }
                }
                
                
                // Actually remove items, if any.
                // Note: Because of the reverse loop above, the indexes in itemsToBeRemoved count down.
                
                for i in itemsToBeRemoved { children!.removeAtIndex(i) }
            }
        }
    }
    
    
    // MARK: - Auxillary stuff and object management
    
    
    /// The custom string convertible protocol.
    /// - Note: Do not use this function to obtain a fully formed JSON code.
    
    var description: String {
        
        // Get rid of subscript generated objects that no longer serve a purpose
        
        self.removeEmptySubscriptObjects()
        
        var str = ""
        
        switch type {
            
        case .NULL:
            
            if name != nil { str += "\"\(name!)\":" }
            str += "null"
            
            
        case .BOOL:
            
            if name != nil { str += "\"\(name!)\":" }
            str += "\(self.bool!)"
            
            
        case .NUMBER:
            
            if name != nil { str += "\"\(name!)\":" }
            str += "\(self.number!)"
            
            
        case .STRING:
            
            if name != nil { str += "\"\(name!)\":" }
            str += "\"\(self.string!)\""
            
            
        case .OBJECT:
            
            if name != nil { str += "\"\(name!)\":" }
            str += "{"
            if children!.count > 0 {
                for ci in 0 ..< children!.count {
                    let c = children![ci]
                    str += c.description
                    if !(c === children![children!.count - 1]) { str += "," }
                }
            }
            str += "}"
            
            
        case .ARRAY:
            
            if name != nil { str += "\"\(name!)\":" }
            str += "["
            if children!.count > 0 {
                for ci in 0 ..< children!.count {
                    let c = children![ci]
                    if c.type == .OBJECT && c.hasName { str += "{" }
                    str += c.description
                    if c.type == .OBJECT && c.hasName { str += "}" }
                    if !(c === children![children!.count - 1]) { str += "," }
                }
            }
            str += "]"
        }
        
        return str
    }
    
    
    /// Initialiser
    
    init(type: JType, name: String?) {
        
        self.type = type
        self.name = name
        
        switch type {
        case .OBJECT, .ARRAY: children = Array<VJson>()
        default: break
        }
    }
    
    
    /// - Returns: A full in-depth copy of this JSON object. I.e. all child elements are also copied.
    
    var copy: VJson {
        let copy = VJson(type: self.type, name: self.name)
        switch type {
        case .NULL: break
        case .BOOL: copy.bool = self.bool!
        case .NUMBER: copy.number = self.number!.copy() as? NSNumber
        case .STRING: copy.string = self.string!
        case .ARRAY, .OBJECT:
            for c in self.children! {
                copy.children!.append(c.copy)
            }
        }
        return copy
    }
    
    
    /**
     Tries to saves the contents of the JSON hierarchy to the specified file.
     
     - Returns: True on success, False on fail.
     */
    
    func save(filepath: NSURL) -> NSError? {
        let str = self.description
        do {
            try str.writeToFile(filepath.path!, atomically: true, encoding: NSUTF8StringEncoding)
            return nil
        } catch let error as NSError {
            return error
        }
    }
    
    
    // MARK: - Static factories
    
    /// Create a VJson hierarchy with the contents of the given file.
    /// Can throw either an VJson.Error.REASON(String) or an NSError if the VJson hierarchy could not be created.
    
    static func createJsonHierarchy(filepath: NSURL) throws -> VJson {
        let data = try NSData(contentsOfFile: filepath.path!, options: NSDataReadingOptions.DataReadingUncached)
        return try parse(UnsafePointer<UInt8>(data.bytes), numberOfBytes: data.length)
    }
    
    static func createJsonHierarchy(buffer: UnsafePointer<UInt8>, length: Int) throws -> VJson {
        return try VJson.parse(buffer, numberOfBytes: length)
    }
    
    
    /**
     Reads an returns a new JSON hierarchy from the mutable data object and removes the found JSON hierarchy from the mutable data object. If no valid JSON hierarchy was found, the mutable data object will be unchanged.
     
     - Returns: The JSON hierarchy.
     
     - Throws: A VJson.Exception if no JSON hierarchy could be read.
     */
    
    static func createJsonHierarchy(buffer: NSMutableData) throws -> VJson {
        return try VJson.parse(buffer)
    }
    
    static func createJsonHierarchy() -> VJson {
        return VJson(type: .OBJECT, name: nil)
    }
    
    static func createNull(name name: String?) -> VJson {
        return VJson(type: .NULL, name: name)
    }
    
    static func createBool(value value: Bool, name: String?) -> VJson {
        let newObject = VJson(type: .BOOL, name: name)
        newObject.bool = value
        return newObject
    }
    
    static func createNumber(value value: NSNumber, name: String?) -> VJson {
        let newObject = VJson(type: .NUMBER, name: name)
        newObject.number = value
        return newObject
    }
    
    static func createNumber(value value: Int, name: String?) -> VJson {
        let newObject = VJson(type: .NUMBER, name: name)
        newObject.number = NSNumber(integer: value)
        return newObject
    }
    
    static func createNumber(value value: Double, name: String?) -> VJson {
        let newObject = VJson(type: .NUMBER, name: name)
        newObject.number = NSNumber(double: value)
        return newObject
    }
    
    static func createNumber(value value: Bool, name: String?) -> VJson {
        let newObject = VJson(type: .NUMBER, name: name)
        newObject.number = NSNumber(bool: value)
        return newObject
    }
    
    static func createString(value value: String, name: String?) -> VJson {
        let newObject = VJson(type: .STRING, name: name)
        newObject.string = value
        return newObject
    }
    
    static func createObject(name name: String?) -> VJson {
        let newObject = VJson(type: .OBJECT, name: name)
        return newObject
    }
    
    static func createObject(withChildren children: Array<VJson?>, name: String?) -> VJson? {
        let newObject = VJson(type: .OBJECT, name: name)
        for child in children.filter({$0 != nil}) {
            if child!.name == nil { return nil }
            if let success = newObject.addChild(child, forName: child!.name!) {
                if !success { return nil }
            } else {
                return nil
            }
        }
        return newObject
    }
    
    static func createArray(name name: String?) -> VJson {
        let newObject = VJson(type: .ARRAY, name: name)
        return newObject
    }
    
    static func createArray(withChildren children: Array<VJson?>, name: String?) -> VJson? {
        let newObject = VJson(type: .ARRAY, name: name)
        for child in children.filter({$0 != nil}) {
            if child!.name != nil { return nil }
            if let success = newObject.appendChild(child) {
                if !success { return nil }
            } else {
                return nil
            }
        }
        return newObject
    }
    
    
    // MARK: Parser functions
    
    /**
    Parses the given sequence of bytes (ASCII or UTF8 encoded) according to ECMA-404, 1st edition October 2013. The sequence should contain exactly one JSON hierarchy. Any errors will result in a throw.
    
    - Parameter buffer: The sequence of bytes to be parsed.
    - Parameter numberOfBytes: The number of bytes to be parsed.
    
    - Returns: On success only, a VJson hierarchy of the parse results.
    
    - Throws: If an error is countered during parsing, the VJson.Exception is thrown.
    */
    
    static func parse(buffer: UnsafePointer<UInt8>, numberOfBytes: Int) throws -> VJson {
        
        guard numberOfBytes > 0 else { throw Exception.REASON(code: 1, incomplete: true, message: "Empty buffer") }
        
        
        // Start at the beginning
        
        var offset: Int = 0
        
        
        // Top level, a value is expected
        
        let val = try readValue(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        
        
        // Only whitespaces allowed after the value
        
        if offset < numberOfBytes {
            
            skipWhitespaces(buffer, numberOfBytes: numberOfBytes, offset: &offset)
            
            if offset < numberOfBytes { throw Exception.REASON(code: 2, incomplete: false, message: "Unexpected characters after end of parsing at offset \(--offset)") }
        }
        
        return val
    }
    
    /**
     Parses the data in the buffer according to ECMA-404, 1st edition October 2013, and creates a VJson hierarchy from it. On success it will also remove the processed data from (front of) the buffer. On failure the buffer will be unaffected.
     
     - Parameter buffer: A buffer containing ASCII or UTF8 characters.
     
     - Returns: A VJson hierarchy of the buffer contents up to the end of the first VJson hierarchy encountered. On success the VJson hierarchy will be removed from the buffer. On failure the buffer will remain unaffected.
     
     - Throws: If an error is countered during parsing, the VJson.Exception is thrown. This exception contains flag that can be used to determine if the error occured due to an incomplete JSON code. The callee then has the opportunity to add more data before trying again.
     */
    
    static func parse(buffer: NSMutableData) throws -> VJson {
        
        guard buffer.length > 0 else { throw Exception.REASON(code: 3, incomplete: true, message: "Empty buffer") }
        
        
        // Start at the beginning
        
        var offset: Int = 0
        
        
        // Top level, a value is expected
        
        let val = try readValue(UnsafePointer<UInt8>(buffer.bytes), numberOfBytes: buffer.length, offset: &offset)
        
        
        // Remove consumed bytes
        
        if offset > 0 {
            let range = NSMakeRange(0, offset)
            buffer.replaceBytesInRange(range, withBytes: nil, length: 0)
        }
        
        return val
    }
    
    
    // MARK: - Private stuff
    
    // The number formatter for the number value
    
    private static var formatter: NSNumberFormatter?
    
    
    // The conversion from string to number using the above number formatter
    
    private static func toDouble(str: String) -> Double? {
        if VJson.formatter == nil {
            VJson.formatter = NSNumberFormatter()
            VJson.formatter!.decimalSeparator = "."
        }
        return VJson.formatter!.numberFromString(str)!.doubleValue
    }
    
    
    // Read the last three characters of a "true" value
    
    private static func readTrue(buffer: UnsafePointer<UInt8>, numberOfBytes: Int, inout offset: Int) throws -> VJson {
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 4, incomplete: true, message: "Illegal value, missing 'r' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_r { throw Exception.REASON(code: 5, incomplete: false, message: "Illegal value, no 'r' in 'true' at offset \(--offset)") }
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 6, incomplete: true, message: "Illegal value, missing 'u' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_u { throw Exception.REASON(code: 7, incomplete: false, message: "Illegal value, no 'u' in 'true' at offset \(--offset)") }
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 8, incomplete: true, message: "Illegal value, missing 'e' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_e { throw Exception.REASON(code: 9, incomplete: false, message: "Illegal value, no 'e' in 'true' at offset \(--offset)") }
        
        return VJson.createBool(value: true, name: nil)
    }
    
    
    // Read the last four characters of a "false" value
    
    private static func readFalse(buffer: UnsafePointer<UInt8>, numberOfBytes: Int, inout offset: Int) throws -> VJson {
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 10, incomplete: true, message: "Illegal value, missing 'a' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_a { throw Exception.REASON(code: 11, incomplete: false, message: "Illegal value, no 'a' in 'true' at offset \(--offset)") }
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 12, incomplete: true, message: "Illegal value, missing 'l' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_l { throw Exception.REASON(code: 13, incomplete: false, message: "Illegal value, no 'l' in 'true' at offset \(--offset)") }
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 14, incomplete: true, message: "Illegal value, missing 's' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_s { throw Exception.REASON(code: 15, incomplete: false, message: "Illegal value, no 's' in 'true' at offset \(--offset)") }
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 16, incomplete: true, message: "Illegal value, missing 'e' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_e { throw Exception.REASON(code: 17, incomplete: false, message: "Illegal value, no 'e' in 'true' at offset \(--offset)") }
        
        return VJson.createBool(value: false, name: nil)
    }
    
    
    // Read the last three characters of a "null" value
    
    private static func readNull(buffer: UnsafePointer<UInt8>, numberOfBytes: Int, inout offset: Int) throws -> VJson {
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 18, incomplete: true, message: "Illegal value, missing 'u' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_u { throw Exception.REASON(code: 19, incomplete: false, message: "Illegal value, no 'u' in 'true' at offset \(--offset)") }
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 20, incomplete: true, message: "Illegal value, missing 'l' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_l { throw Exception.REASON(code: 21, incomplete: false, message: "Illegal value, no 'l' in 'true' at offset \(--offset)") }
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 22, incomplete: true, message: "Illegal value, missing 'l' in 'true' at end of buffer") }
        if buffer[offset++] != ASCII_l { throw Exception.REASON(code: 23, incomplete: false, message: "Illegal value, no 'l' in 'true' at offset \(--offset)") }
        
        return VJson.createNull(name: nil)
    }
    
    
    // Read the next characters as a string, ends with non-escaped double quote
    
    private static func readString(buffer: UnsafePointer<UInt8>, numberOfBytes: Int, inout offset: Int) throws -> VJson {
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 24, incomplete: true, message: "Missing end of string at end of buffer") }
        
        var strbuf = Array<UInt8>()
        
        var stringEnd = false
        
        while !stringEnd {
            
            if buffer[offset] == ASCII_DOUBLE_QUOTES {
                stringEnd = true
            } else {
                
                if buffer[offset] == ASCII_BACKSLASH {
                    
                    offset++
                    if offset >= numberOfBytes { throw Exception.REASON(code: 25, incomplete: true, message: "Missing end of string at end of buffer") }
                    
                    switch buffer[offset] {
                    case ASCII_DOUBLE_QUOTES, ASCII_BACKWARD_SLASH, ASCII_FOREWARD_SLASH: strbuf.append(buffer[offset])
                    case ASCII_b: strbuf.append(ASCII_BACKSPACE)
                    case ASCII_f: strbuf.append(ASCII_FORMFEED)
                    case ASCII_n: strbuf.append(ASCII_NEWLINE)
                    case ASCII_r: strbuf.append(ASCII_CARRIAGE_RETURN)
                    case ASCII_t: strbuf.append(ASCII_TAB)
                    case ASCII_u:
                        strbuf.append(buffer[offset])
                        offset++
                        if offset >= numberOfBytes { throw Exception.REASON(code: 26, incomplete: true, message: "Missing second byte after \\u in string") }
                        strbuf.append(buffer[offset])
                        offset++
                        if offset >= numberOfBytes { throw Exception.REASON(code: 27, incomplete: true, message: "Missing third byte after \\u in string") }
                        strbuf.append(buffer[offset])
                        offset++
                        if offset >= numberOfBytes { throw Exception.REASON(code: 28, incomplete: true, message: "Missing fourth byte after \\u in string") }
                        strbuf.append(buffer[offset])
                    default:
                        throw Exception.REASON(code: 29, incomplete: false, message: "Illegal character after \\ in string")
                    }
                    
                } else {
                    
                    strbuf.append(buffer[offset])
                }
            }
            
            offset++
            if offset >= numberOfBytes { throw Exception.REASON(code: 30, incomplete: true, message: "Missing end of string at end of buffer") }
        }
        
        if let str: String = String(bytes: strbuf, encoding: NSUTF8StringEncoding) {
            return VJson.createString(value: str, name: nil)
        } else {
            throw Exception.REASON(code: 31, incomplete: false, message: "NSUTF8StringEncoding conversion failed at offset \(--offset)")
        }
        
    }
    
    private static func readNumber(buffer: UnsafePointer<UInt8>, numberOfBytes: Int, inout offset: Int) throws -> VJson {
        
        var numbuf = Array<UInt8>()
        
        // Sign
        if buffer[offset] == ASCII_MINUS {
            numbuf.append(buffer[offset++])
            if offset >= numberOfBytes { throw Exception.REASON(code: 32, incomplete: true, message: "Missing number at end of buffer") }
        }
        
        // First digit series
        if buffer[offset].isAsciiNumber {
            while buffer[offset].isAsciiNumber {
                numbuf.append(buffer[offset++])
                // If the original string is a fraction, it could end right after the number
                if offset >= numberOfBytes {
                    if let numstr = String(bytes: numbuf, encoding: NSUTF8StringEncoding) {
                        if let double = toDouble(numstr) {
                            return VJson.createNumber(value: double, name: nil)
                        } else {
                            throw Exception.REASON(code: 33, incomplete: false, message: "Could not convert to double at end of buffer") // Probably impossible
                        }
                    } else {
                        throw Exception.REASON(code: 34, incomplete: false, message: "NSUTF8StringEncoding conversion failed at end of buffer")
                    }
                }
            }
        } else {
            throw Exception.REASON(code: 35, incomplete: false, message: "Illegal character in number at offset \(offset)")
        }
        
        // Fraction
        if buffer[offset] == ASCII_DOT {
            numbuf.append(buffer[offset++])
            if offset >= numberOfBytes { throw Exception.REASON(code: 36, incomplete: true, message: "Missing digits (expecting fraction) at offset \(--offset)") }
            if buffer[offset].isAsciiNumber {
                while buffer[offset].isAsciiNumber {
                    numbuf.append(buffer[offset++])
                    // If the original string is a fraction, it could end right after the number
                    if offset >= numberOfBytes {
                        if let numstr = String(bytes: numbuf, encoding: NSUTF8StringEncoding) {
                            if let double = toDouble(numstr) {
                                return VJson.createNumber(value: double, name: nil)
                            } else {
                                throw Exception.REASON(code: 37, incomplete: false, message: "Could not convert to double at end of buffer") // Probably impossible
                            }
                        } else {
                            throw Exception.REASON(code: 38, incomplete: false, message: "NSUTF8StringEncoding conversion failed at end of buffer")
                        }
                    }
                }
            } else {
                throw Exception.REASON(code: 39, incomplete: false, message: "Illegal character in fraction at offset \(offset)")
            }
        }
        
        // Mantissa
        if buffer[offset] == ASCII_e || buffer[offset] == ASCII_E {
            numbuf.append(buffer[offset++])
            if offset >= numberOfBytes { throw Exception.REASON(code: 40, incomplete: true, message: "Missing mantissa at buffer end") }
            if buffer[offset] == ASCII_MINUS || buffer[offset] == ASCII_PLUS {
                numbuf.append(buffer[offset++])
                if offset >= numberOfBytes { throw Exception.REASON(code: 41, incomplete: true, message: "Missing mantissa at buffer end") }
            }
            if buffer[offset].isAsciiNumber {
                while buffer[offset].isAsciiNumber {
                    numbuf.append(buffer[offset++])
                    if offset >= numberOfBytes { break }
                }
            } else {
                throw Exception.REASON(code: 42, incomplete: false, message: "Illegal character in mantissa at offset \(offset)")
            }
        }
        
        // Number completed
        
        if let numstr = String(bytes: numbuf, encoding: NSUTF8StringEncoding) {
            return VJson.createNumber(value: (toDouble(numstr) ?? Double(0.0)), name: nil)
        } else {
            throw Exception.REASON(code: 43, incomplete: false, message: "NSUTF8StringEncoding conversion failed for number ending at offset \(--offset)")
        }
        
    }
    
    private static func readArray(buffer: UnsafePointer<UInt8>, numberOfBytes: Int, inout offset: Int) throws -> VJson {
        
        skipWhitespaces(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 44, incomplete: true, message: "Missing array end at end of buffer") }
        
        
        let result = VJson(type: .ARRAY, name: nil)
        
        
        // Index points at value or end-of-array bracket
        
        if buffer[offset] == ASCII_SQUARE_BRACKET_CLOSE {
            offset++
            return result
        }
        
        
        // The offset should point at a value
        
        while offset < numberOfBytes {
            
            let value = try readValue(buffer, numberOfBytes: numberOfBytes, offset: &offset)
            
            // Value received, walk to the next "]" or "," or end of json
            
            skipWhitespaces(buffer, numberOfBytes: numberOfBytes, offset: &offset)
            
            if offset >= numberOfBytes { throw Exception.REASON(code: 45, incomplete: true, message: "Missing array end at end of buffer") }
            
            if buffer[offset] == ASCII_COMMA {
                result.appendChild(value)
                offset++
            } else if buffer[offset] == ASCII_SQUARE_BRACKET_CLOSE {
                offset++
                result.appendChild(value)
                return result
            } else {
                throw Exception.REASON(code: 58, incomplete: false, message: "Expected comma or end-of-array bracket")
            }
        }
        
        throw Exception.REASON(code: 46, incomplete: true, message: "Missing array end at end of buffer")
    }
    
    
    // The value should never return an .ERROR type. If an error occured it should be reported through the errorString and errorReason.
    
    private static func readValue(buffer: UnsafePointer<UInt8>, numberOfBytes: Int, inout offset: Int) throws -> VJson {
        
        skipWhitespaces(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 47, incomplete: true, message: "Missing value at end of buffer") }
        
        
        // index points at non-whitespace
        
        var val: VJson
        
        switch buffer[offset++] {
        case ASCII_BRACE_OPEN: val = try readObject(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        case ASCII_SQUARE_BRACKET_OPEN: val = try readArray(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        case ASCII_DOUBLE_QUOTES: val = try readString(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        case ASCII_MINUS: --offset; val = try readNumber(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        case ASCII_0...ASCII_9: --offset; val = try readNumber(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        case ASCII_n: val = try readNull(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        case ASCII_f: val = try readFalse(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        case ASCII_t: val = try readTrue(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        default: throw Exception.REASON(code: 48, incomplete: false, message: "Illegal character at start of value at offset \(offset)")
        }
        
        return val
    }
    
    private static func readObject(buffer: UnsafePointer<UInt8>, numberOfBytes: Int, inout offset: Int) throws -> VJson {
        
        skipWhitespaces(buffer, numberOfBytes: numberOfBytes, offset: &offset)
        
        if offset >= numberOfBytes { throw Exception.REASON(code: 49, incomplete: true, message: "Missing object end at end of buffer") }
        
        
        // Result object
        
        let result = VJson(type: .OBJECT, name: nil)
        
        
        // Index points at non-whitespace
        
        if buffer[offset] == ASCII_BRACE_CLOSE {
            offset++
            return result
        }
        
        
        // Add name/value pairs
        
        while offset < numberOfBytes {
            
            
            // The offset should point at "
            
            var name: String
            
            if buffer[offset] == ASCII_DOUBLE_QUOTES {
                
                offset++
                let str = try readString(buffer, numberOfBytes: numberOfBytes, offset: &offset)
                
                if str.type == .STRING {
                    name = str.string!
                } else {
                    throw Exception.REASON(code: 50, incomplete: false, message: "Programming error")
                }
                
            } else {
                throw Exception.REASON(code: 51, incomplete: false, message: "Expected double quotes of name in name/value pair at offset \(offset)")
            }
            
            
            // The colon is next
            
            skipWhitespaces(buffer, numberOfBytes: numberOfBytes, offset: &offset)
            
            if offset >= numberOfBytes { throw Exception.REASON(code: 52, incomplete: true, message: "Missing ':' in name/value pair at offset \(--offset)") }
            
            if buffer[offset] != ASCII_COLON {
                throw Exception.REASON(code: 53, incomplete: false, message: "Missing ':' in name/value pair at offset \(offset)")
            }
            
            offset++ // Consume the ":"
            
            
            // A value should be next
            
            skipWhitespaces(buffer, numberOfBytes: numberOfBytes, offset: &offset)
            
            if offset >= numberOfBytes { throw Exception.REASON(code: 54, incomplete: true, message: "Missing value of name/value pair at buffer end") }
            
            let val = try readValue(buffer, numberOfBytes: numberOfBytes, offset: &offset)
            
            
            // Add the name/value pair to this object
            
            val.name = name
            result.addChild(val, forName: name)
            
            
            // A comma or brace end should be next
            
            skipWhitespaces(buffer, numberOfBytes: numberOfBytes, offset: &offset)
            
            if offset >= numberOfBytes { throw Exception.REASON(code: 55, incomplete: true, message: "Missing end of object at buffer end") }
            
            if buffer[offset] == ASCII_BRACE_CLOSE {
                offset++
                return result
            }
            
            if buffer[offset] != ASCII_COMMA { throw Exception.REASON(code: 56, incomplete: false, message: "Unexpected character, expected comma at offset \(offset)") }
            
            offset++
            
        }
        
        throw Exception.REASON(code: 57, incomplete: true, message: "Missing name in name/value pair of object at buffer end")
    }
    
    private static func skipWhitespaces(buffer: UnsafePointer<UInt8>, numberOfBytes: Int, inout offset: Int) {
        
        if offset >= numberOfBytes { return }
        while buffer[offset].isAsciiWhitespace {
            offset++
            if offset >= numberOfBytes { break }
        }
    }
}