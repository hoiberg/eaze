//
//  PIDSnapshot.swift
//  CleanflightMobile
//
//  Created by Alex on 14-10-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import UIKit

final class TuningSnapshot: NSObject {
    
    // MARK: - Variables
    
    var fileURL: URL?,
        version: Version = "1.0.0",
        name = "unknown",
        date = Date(),
        PIDController = 0
    
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
    
    /// Create from data currently in dataStorage
    init(name: String) {
        super.init()
        
        self.name       = name
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
        yawExpo         = dataStorage.yawExpo
        dynamicThrottlePID        = dataStorage.dynamicThrottlePID
        dynamicThrottleBreakpoint = dataStorage.dynamicThrottleBreakpoint
        PIDs            = dataStorage.PIDs
        
        save()
    }
    
    /// Create from data in file
    init(file: URL) {
        super.init()
        
        do {
            fileURL = file
            let json = try VJson.parse(file: file),
                snapshot = json["tuningsnapshot"]
            
            version = Version(string: snapshot["snapshotversion"].stringValue ?? "1.0.0")
            name = snapshot["name"].stringValue ?? "unknown"
            date = Date(timeIntervalSinceReferenceDate: snapshot["date"].doubleValue ?? 0.0)
            PIDController = snapshot["pidcontroller"].intValue ?? 0
            rcRate = snapshot["rcrate"].doubleValue ?? 0.0
            rcExpo = snapshot["rcexpo"].doubleValue ?? 0.0
            throttleMid = snapshot["thrmid"].doubleValue ?? 0.0
            throttleExpo = snapshot["threxp"].doubleValue ?? 0.0
            rollRate = snapshot["rollrate"].doubleValue ?? 0.0
            pitchRate = snapshot["pitchrate"].doubleValue ?? 0.0
            yawRate = snapshot["yawrate"].doubleValue ?? 0.0
            yawExpo = snapshot["yawexpo"].doubleValue ?? 0.0
            dynamicThrottlePID = snapshot["tpa"].doubleValue ?? 0.0
            dynamicThrottleBreakpoint = snapshot["tpabreakpoint"].intValue ?? 0
            
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
            log(.Error, "Failed to a read tuning snapshot at url: \(file.path), error: \(error)")
            return
        }
    }
    
    /// Save to file
    func save() {
        let json = VJson(),
            snapshot = json["tuningsnapshot"]
        
        snapshot["snapshotversion"].stringValue = version.stringValue
        snapshot["name"].stringValue = name
        snapshot["date"].doubleValue = date.timeIntervalSinceReferenceDate
        snapshot["pidcontroller"].intValue = PIDController
        snapshot["rcrate"].doubleValue = rcRate
        snapshot["rcexpo"].doubleValue = rcExpo
        snapshot["thrmid"].doubleValue = throttleMid
        snapshot["threxp"].doubleValue = throttleExpo
        snapshot["rollrate"].doubleValue = rollRate
        snapshot["pitchrate"].doubleValue = pitchRate
        snapshot["yawrate"].doubleValue = yawRate
        snapshot["yawexpo"].doubleValue = yawExpo
        snapshot["tpa"].doubleValue = dynamicThrottlePID
        snapshot["tpabreakpoint"].intValue = dynamicThrottleBreakpoint
        
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
                let fileManager = FileManager.default,
                    docsURL = try TuningSnapshot.getDocumentsDirectory()
                
                var suffix = 0,
                    docName = name == "" ? "unknown" : name
                
                docName = docName.replacingOccurrences(of: ".", with: "_")
                docName = docName.replacingOccurrences(of: " ", with: "_")
                docName = docName.replacingOccurrences(of: "/", with: "_")
                docName = docName.replacingOccurrences(of: "?", with: "_")
                docName = docName.replacingOccurrences(of: "*", with: "_")

                // write to file that doesn't exist already
                var docPath = "\(docsURL.path)/\(docName).json"
                if fileManager.fileExists(atPath: docPath) {
                    while fileManager.fileExists(atPath: "\(docsURL.path)/\(docName)-\(suffix).json") { suffix += 1 }
                    docPath = "\(docsURL.path)/\(docName)-\(suffix).json"
                }
                fileURL = URL(string: docPath)
                if let url = fileURL {
                    if let error = json.save(to: url) {
                        log(.Error, "Error while saving tuning snapshot: \(error)")
                    }
                } else {
                    log(.Error, "Failed to create url while saving tuning snapshot: \(docPath)")
                }
            } catch let error as NSError {
                log(.Error, "Failed to create url for new tuning snapshot: \(error.localizedDescription)")
            }
        } else {
            // just overwrite existing file
            if let error = json.save(to: fileURL!) {
                log(.Error, "Error while saving tuning snapshot: \(error)")
            }
        }
    }
    
    /// Send data to fc and save to eeprom
    func uploadToFlightController() {
        // MSP_SET_PID
        dataStorage.PIDs = PIDs
        msp.crunchAndSendMSP(MSP_SET_PID)
        
        // MSP_SET_RC_TUNING
        dataStorage.rcRate = rcRate
        dataStorage.rcExpo = rcExpo
        dataStorage.throttleMid = throttleMid
        dataStorage.throttleExpo = throttleExpo
        dataStorage.rollPitchRate = rollRate
        dataStorage.rollRate = rollRate
        dataStorage.pitchRate = pitchRate
        dataStorage.yawRate = yawRate
        dataStorage.yawExpo = yawExpo
        dataStorage.dynamicThrottlePID = dynamicThrottlePID
        dataStorage.dynamicThrottleBreakpoint = dynamicThrottleBreakpoint
        msp.crunchAndSendMSP(MSP_SET_RC_TUNING)
        
        var codes = [MSP_SET_PID, MSP_SET_RC_TUNING]

        // MSP_SET_PID_CONTROLLER
        if dataStorage.apiVersion >= pidControllerChangeMinApiVersion {
            dataStorage.PIDController = PIDController
            codes.append(MSP_SET_PID_CONTROLLER)
        }
        
        msp.crunchAndSendMSP(codes) {
            msp.sendMSP(MSP_EEPROM_WRITE) { // save
                msp.sendMSP([MSP_PID, MSP_RC_TUNING, MSP_PID_CONTROLLER]) // reload (also reloads UI)
            }
        }
    }
    
    /// Returns all TuningSnapshots in the docs directory
    class func loadAllSnapshots() -> [TuningSnapshot] {
        do {
            // get docs dir, and all files with .json extension
            let docsURL = try getDocumentsDirectory(),
                contents = try FileManager.default.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions()),
                snapshotPaths = contents.filter(){ $0.pathExtension == "json" }
            
            // read all snapshots & return thosse
            var snapshots: [TuningSnapshot] = []
            for path in snapshotPaths {
                snapshots.append(TuningSnapshot(file: path))
            }
            
            // sort & return
            return snapshots.sorted(){ $0.date > $1.date }
            
        } catch let error as NSError {
            log(.Error, "Failed to read tuning snapshots: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Delete a snapshot (ereases the file it is stored in)
    class func deleteSnapshot(_ snapshot: TuningSnapshot) {
        if let url = snapshot.fileURL {
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError {
                log(.Error, "Failed to delete tuning snapshot: \(error.localizedDescription)")
            }
        }
    }
    
    /// Returns he directory all snapshots are stored in
    fileprivate class func getDocumentsDirectory() throws -> URL {
        do {
            // get docs dir
            let fileManager = FileManager.default
            var docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            docsURL = docsURL.appendingPathComponent("tuningsnapshots", isDirectory: true)
            
            // or create if it doesn't yet exist
            var isDir = ObjCBool(true)
            if !fileManager.fileExists(atPath: docsURL.path, isDirectory: &isDir) {
                try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: false, attributes: nil)
            }
            
            return docsURL
            
        } catch let error as NSError {
            log(.Error, "Failed to get snapshots url: \(error.localizedDescription)")
            throw error
        }
    }
}
