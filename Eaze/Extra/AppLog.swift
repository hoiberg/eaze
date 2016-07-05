//
//  AppLog.swift
//  CleanflightMobile
//
//  Created by Alex on 29-03-16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

final class AppLog: NSObject {
    
    enum Level: String {
        case Fatal, Error, Warn, Info, Debug, Trace
    }
    
    var fileHandle: NSFileHandle?
    let dateFormatter: NSDateFormatter,
              fileURL: NSURL
    
    override init() {
        // dateformatter
        dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        // fileurl
        let fileManager = NSFileManager.defaultManager(),
              directory = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
                fileURL = directory.URLByAppendingPathComponent("AppLog.txt")
        
        // create if nonexistent
        if !fileManager.fileExistsAtPath(fileURL.path!) {
            fileManager.createFileAtPath(fileURL.path!, contents: nil, attributes: nil)
        }
        
        // filehandle
        do { fileHandle = try NSFileHandle(forWritingToURL: fileURL) }
        catch { print("Unable to create fileHandle for URL: \(fileURL.path!)") }
        
        super.init()
    }
    
    deinit {
        fileHandle?.synchronizeFile()
        fileHandle?.closeFile()
    }

    func log(level: Level, message: String) {
        // generate actual log text
        var finalStr = dateFormatter.stringFromDate(NSDate()) + " "
        if level != .Info { finalStr +=  level.rawValue.uppercaseString + ": " }
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
            do { fileHandle = try NSFileHandle(forWritingToURL: fileURL) }
            catch { print("Unable to create fileHandle for URL: \(fileURL.path!)") }
        }
        
        // generate data
        let data = finalStr.dataUsingEncoding(NSUTF8StringEncoding)!
        
        // write to file
        fileHandle?.writeData(data)
        fileHandle?.synchronizeFile()
    }
    
    func loadLog() -> String {
        do {
            return try String(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding)
        } catch {
            print("Failed to load log, error: \(error)")
            return "Failed to load log, error: \(error)"
        }
    }
    
    func halveLog() {
        // sperate function so we can easily test this
        do {
            let temp = try NSString(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding),
            length = temp.length/2,
            range = NSMakeRange(length, length),
            data = temp.substringWithRange(range).dataUsingEncoding(NSUTF8StringEncoding)
            data!.writeToURL(fileURL, atomically: true)
        } catch {
            print("Failed to cut size of log file: \(error)")
        }
    }
}

func log(message: String) {
    console.log(.Info, message: message)
}

func log(level: AppLog.Level, _ message: String) {
    console.log(level, message: message)
}