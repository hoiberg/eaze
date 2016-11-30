//
//  AppLog.swift
//  CleanflightMobile
//
//  Created by Alex on 29-03-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


final class AppLog: NSObject {
    
    enum Level: String {
        case Fatal, Error, Warn, Info, Debug, Trace
    }
    
    var fileHandle: FileHandle?
    let dateFormatter: DateFormatter,
              fileURL: URL
    
    override init() {
        // dateformatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        // fileurl
        let fileManager = FileManager.default,
              directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
                fileURL = directory.appendingPathComponent("AppLog.txt")
        
        // create if nonexistent
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        
        // filehandle
        do { fileHandle = try FileHandle(forWritingTo: fileURL) }
        catch { print("Unable to create fileHandle for URL: \(fileURL.path)") }
        
        super.init()
    }
    
    deinit {
        fileHandle?.synchronizeFile()
        fileHandle?.closeFile()
    }

    func log(_ level: Level, message: String) {
        // generate actual log text
        var finalStr = dateFormatter.string(from: Date()) + " "
        if level != .Info { finalStr +=  level.rawValue.uppercased() + ": " }
        finalStr += message + "\n"
        
        if level == .Fatal || level == .Error || level == .Warn {
            print(finalStr, terminator: "")
        }
        
        #if DEBUG
        if level == .Info || level == .Debug || level == .Trace {
            print(finalStr, terminator: "")
        }
        #endif
        
        // limit file size
        if fileHandle?.seekToEndOfFile() > 10000 { // 10kB max file size
            fileHandle?.closeFile()
            halveLog()
            do { fileHandle = try FileHandle(forWritingTo: fileURL) }
            catch { print("Unable to create fileHandle for URL: \(fileURL.path)") }
        }
        
        // generate data
        let data = finalStr.data(using: String.Encoding.utf8)!
        
        // write to file
        fileHandle?.write(data)
        fileHandle?.synchronizeFile()
    }
    
    func loadLog() -> String {
        do {
            return try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to load log, error: \(error)")
            return "Failed to load log, error: \(error)"
        }
    }
    
    func halveLog() {
        // sperate function so we can easily test this
        do {
            let temp = try NSString(contentsOf: fileURL, encoding: String.Encoding.utf8.rawValue),
            length = temp.length/2,
            range = NSMakeRange(length, length),
            data = temp.substring(with: range).data(using: String.Encoding.utf8)
            try? data!.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to cut size of log file: \(error)")
        }
    }
}

func log(_ message: String) {
    console.log(.Info, message: message)
}

func log(_ level: AppLog.Level, _ message: String) {
    console.log(level, message: message)
}
