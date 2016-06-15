//
//  PIDSnapshot.swift
//  CleanflightMobile
//
//  Created by Alex on 14-10-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

class TuningSnapshot: NSObject {
    
    // MARK: - Variables
    
    /// URL of the file this snapshot is stored at
    var fileURL: NSURL?
    
    /// Current version of this TuningSnapshot (NOT OF THE CLEANFLIGHT VERSION THIS WAS CREATED WITH)
    var version: Version = "1.0.0"
    
    /// Name of this snapshot (specified by the user)
    var name = "unknown"
    
    /// Date & time this snapshot was created
    var date = NSDate()
    
    /// Select PID controller
    var PIDController = 0
    
    //  Tuning
    var rcRate              = 0.0,
        rcExpo              = 0.0,
        throttleMid         = 0.0,
        throttleExpo        = 0.0,
        rollRate            = 0.0,
        pitchRate           = 0.0,
        yawRate             = 0.0,
        yawExpo             = 0.0,
        dynamicThrottlePID  = 0.0,
        dynamicThrottleBreakpoint = 0
    
    /// PID data in default order (ROLL / PITCH / YAW / ALT / POS / POSR / NAVR / LEVEL / MAG / VEL)
    var PIDs: [[Double]] = []


    // MARK: - Functions
    
    /// Create new TuningSnapshot from current tuning data in DataStorage
    init(name: String) {
        
        super.init()
        
        self.name       = name

        
        // copy from DataStorage
        
        PIDController   = dataStorage.PIDController
        rcRate          = dataStorage.rcRate
        rcExpo          = dataStorage.rcExpo
        throttleMid     = dataStorage.throttleMid
        throttleExpo    = dataStorage.throttleExpo
        if dataStorage.apiVersion < "1.7.0" {
            rollRate    = dataStorage.rollPitchRate
            pitchRate   = dataStorage.rollPitchRate
        } else {
            rollRate    = dataStorage.rollRate
            pitchRate   = dataStorage.pitchRate
        }
        yawRate         = dataStorage.yawRate
        dynamicThrottlePID        = dataStorage.dynamicThrottlePID
        dynamicThrottleBreakpoint = dataStorage.dynamicThrottleBreakpoint
        PIDs            = dataStorage.PIDs
        
        
        save()
    }
    
    /// Load TuningSnapshot from file
    init(file: NSURL) {
        super.init()
        
        do {
            fileURL = file
            let json = try VJson.createJsonHierarchy(file)
            
            // get snapshot json object
            let snapshot = json["tuningsnapshot"]
            
            // populate data of this object
            version = Version(string: snapshot["snapshotversion"].stringValue ?? "1.0.0")
            name = snapshot["name"].stringValue ?? "unknown"
            date = NSDate(timeIntervalSinceReferenceDate: snapshot["date"].doubleValue ?? 0.0)
            PIDController = snapshot["pidcontroller"].integerValue ?? 0
            rcRate = snapshot["rcrate"].doubleValue ?? 0.0
            rcExpo = snapshot["rcexpo"].doubleValue ?? 0.0
            throttleMid = snapshot["thrmid"].doubleValue ?? 0.0
            throttleExpo = snapshot["threxp"].doubleValue ?? 0.0
            rollRate = snapshot["rollrate"].doubleValue ?? 0.0
            pitchRate = snapshot["pitchrate"].doubleValue ?? 0.0
            yawRate = snapshot["yawrate"].doubleValue ?? 0.0
            dynamicThrottlePID = snapshot["tpa"].doubleValue ?? 0.0
            dynamicThrottleBreakpoint = snapshot["tpabreakpoint"].integerValue ?? 0
            
            // get PID array
            var needle = 0
            for _ in 0...9 {
                var triple: [Double] = []
                for _ in 0...2 {
                    triple.append(snapshot["pid"][needle++].doubleValue!)
                }
                PIDs.append(triple)
            }
        } catch {
            log(.Error, "Failed to a read tuning snapshot at url: \(file.path!), error: \(error)")
            return
        }
    }
    
    /// Save TuningSnapshot to file
    func save() {
        
        // create new JSON object & set all values
        let json = VJson.createJsonHierarchy()
        let snapshot = json["tuningsnapshot"]
        snapshot["snapshotversion"].stringValue = version.stringValue
        snapshot["name"].stringValue = name
        snapshot["date"].doubleValue = date.timeIntervalSinceReferenceDate
        snapshot["pidcontroller"].integerValue = PIDController
        snapshot["rcrate"].doubleValue = rcRate
        snapshot["rcexpo"].doubleValue = rcExpo
        snapshot["thrmid"].doubleValue = throttleMid
        snapshot["threxp"].doubleValue = throttleExpo
        snapshot["rollrate"].doubleValue = rollRate
        snapshot["pitchrate"].doubleValue = pitchRate
        snapshot["yawrate"].doubleValue = yawRate
        snapshot["tpa"].doubleValue = dynamicThrottlePID
        snapshot["tpabreakpoint"].integerValue = dynamicThrottleBreakpoint
        
        // add pid array
        var needle = 0
        for triple in PIDs {
            for value in triple {
                snapshot["pid"][needle++].doubleValue = value
            }
        }
        
        // create a new unique url if needed
        if fileURL == nil {
            do {
                let fileManager = NSFileManager.defaultManager()
                let docsURL = try TuningSnapshot.getDocumentsDirectory()
                let docName = name == "" ? "unknown" : name
                var suffix = 0
                
                // write to file that doesn't exist already
                var docPath = "\(docsURL.path!)/\(docName).json"
                if fileManager.fileExistsAtPath(docPath) {
                    while fileManager.fileExistsAtPath("\(docsURL.path!)/\(docName)-\(suffix).json") { suffix++ }
                    docPath = "\(docsURL.path!)/\(docName)-\(suffix).json"
                }
                fileURL = NSURL(string: docPath)
                if let url = fileURL {
                        if let error = json.save(url) { //TODO: FOUND NIL
                            log(.Error, "Error while saving tuning snapshot: \(error.localizedDescription)")
                        }
                } else {
                    log(.Error, "Failed to create url while saving tuning snapshot: \(docPath)")
                }
            } catch let error as NSError {
                log(.Error, "Failed to create url for new tuning snapshot: \(error.localizedDescription)")
            }
        } else {
            // just overwrite existing file
            if let error = json.save(fileURL!) {
                log(.Error, "Error while saving tuning snapshot: \(error.localizedDescription)")
            }
        }
    }
    
    /// Send data to fc and save to eeprom
    func uploadToFlightController() {
        
        // send PIDs to FC
        dataStorage.PIDs = PIDs
        msp.crunchAndSendMSP(MSP_SET_PID)
        
        // send rc tuning data to FC
        dataStorage.rcRate = rcRate
        dataStorage.rcExpo = rcExpo
        dataStorage.throttleMid = throttleMid
        dataStorage.throttleExpo = throttleExpo
        dataStorage.rollPitchRate = rollRate
        dataStorage.rollRate = rollRate
        dataStorage.pitchRate = pitchRate
        dataStorage.yawRate = yawRate
        dataStorage.dynamicThrottlePID = dynamicThrottlePID
        dataStorage.dynamicThrottleBreakpoint = dynamicThrottleBreakpoint
        msp.crunchAndSendMSP(MSP_SET_RC_TUNING)
        
        // send PID controller
        dataStorage.PIDController = PIDController
        msp.crunchAndSendMSP(MSP_SET_PID_CONTROLLER)
        
        // save data to eeprom
        msp.sendMSP(MSP_EEPROM_WRITE)
    }
    
    /// Returns all TuningSnapshots in the docs directory
    class func loadAllSnapshots() -> [TuningSnapshot] {
        do {
            // get docs dir
            let docsURL = try getDocumentsDirectory()
            
            // get all files in it with a .json extension
            let contents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(docsURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
            let snapshotPaths = contents.filter(){ $0.pathExtension == "json" }
            
            // read all snapshots & return thosse
            var snapshots: [TuningSnapshot] = []
            for path in snapshotPaths {
                snapshots.append(TuningSnapshot(file: path))
            }
            
            // sort & return
            return snapshots.sort(){ $0.date > $1.date }
            
        } catch let error as NSError {
            log(.Error, "Failed to read tuning snapshots: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Delete a snapshot (ereases the file it is stored in)
    class func deleteSnapshot(snapshot: TuningSnapshot) {
        if let url = snapshot.fileURL {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(url)
            } catch let error as NSError {
                print("Failed to delete tuning snapshot: \(error.localizedDescription)")
            }
        }
    }
    
    /// Returns he directory all snapshots are stored in
    private class func getDocumentsDirectory() throws -> NSURL {
        do {
            // get docs dir
            let fileManager = NSFileManager.defaultManager()
            var docsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            docsURL = docsURL.URLByAppendingPathComponent("tuningsnapshots", isDirectory: true)
            
            // or create if it doesn't yet exist
            var isDir = ObjCBool(true)
            if !fileManager.fileExistsAtPath(docsURL.path!, isDirectory: &isDir) {
                try fileManager.createDirectoryAtURL(docsURL, withIntermediateDirectories: false, attributes: nil)
            }
            
            return docsURL
            
        } catch let error as NSError {
            log(.Error, "Failed to get snapshots url: \(error.localizedDescription)")
            throw error
        }
    }
}