//
//  Wheel.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 1/1/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation
import UIKit

public class Wheel : NSObject, DatabaseObjectProtocol {
    
    public var uuid : String = ""
    public var name : String = ""
    public var password : String  = "000000"
    public var brand : String = ""
    public var serialNo : String = ""
    public var model : String = ""
    public var version : String = "1.1.1"
    public var maxSpeed : Double = 8.33    // Max speed m/s
    public var limitSpeed : Double = 8.33  // Limited speed (from the wheel)
    public var alarmSpeed : Double = 5.56  // Applcation Alarm Speed
    public var notifySpeed : Bool = false
    public var batteryAlarm : Double = 20 // Battery alarm. 20%
    public var notifyBattery : Bool = true
    public var totalDistance : Double = 0.0    // Just to get the total distance. Updated with every run
    
    
    // Distance adjustment
    
    var nruns : Int = 0     // Number of runs
    
     // Distance and speed adjustment
    
    var distance_sum_xy : Double = 1.0    // sum (distanceGPS * distance)
    var distance_sum_x2  : Double = 1.0   // sum (distanceGPS ^2)
    public var distance_coef : Double = 1.0      // distance = distanceGPS/coef  o distance real = distance *  coef
    
    
    var speed_sum_xy : Double = 1.0    // sum (distanceGPS * speed integral)
    public var speed_coef : Double = 1.0      // speed_real = speed * coef
    
    public var enableCorrections : Bool = false // If corrections are enabled or not
    
    public init(uuid : String, name : String){
        //super.init()
        self.uuid = uuid
        self.name = name
    }
    
    //MARK: DatabaseAccessProtocol
    
    public func initWithCoder(_ decoder : NSCoder){
        
        self.uuid = decoder.decodeObject(forKey: "uuid") as? String ?? ""
        self.name = decoder.decodeObject(forKey: "name") as? String ?? ""
        self.password = decoder.decodeObject(forKey: "password") as? String ?? ""
        self.brand = decoder.decodeObject(forKey: "brand") as? String ?? ""
        self.serialNo = decoder.decodeObject(forKey: "serialNo") as? String ?? ""
        self.model = decoder.decodeObject(forKey: "model") as? String ?? ""
        self.version = decoder.decodeObject(forKey: "version") as? String ?? ""
        self.maxSpeed = decoder.decodeDouble(forKey: "maxSpeed")
        self.limitSpeed = decoder.decodeDouble(forKey: "limitSpeed")
        self.alarmSpeed = decoder.decodeDouble(forKey: "alarmSpeed")
        self.notifySpeed = decoder.decodeBool(forKey: "notifySpeed")
        self.batteryAlarm = decoder.decodeDouble(forKey: "batteryAlarm")
        self.notifyBattery = decoder.decodeBool(forKey: "notifyBattery")
        self.totalDistance = decoder.decodeDouble(forKey: "totalDistance")
        
        self.nruns = decoder.decodeInteger(forKey: "nruns")
        self.distance_sum_xy = decoder.decodeDouble(forKey: "distance_sum_xy")
        self.distance_sum_x2 = decoder.decodeDouble(forKey: "distance_sum_x2")
        self.distance_coef = decoder.decodeDouble(forKey: "distance_coef")
        self.speed_sum_xy = decoder.decodeDouble(forKey: "speed_sum_xy")
        self.speed_coef = decoder.decodeDouble(forKey: "speed_coef")
        self.enableCorrections = decoder.decodeBool(forKey: "enableCorrections")
        
        
        
        
    }
    
    public func encodeWithCoder(_ encoder: NSCoder){
        
        encoder.encode(uuid, forKey:"uuid")
        encoder.encode(name, forKey:"name")
        encoder.encode(password, forKey:"password")
        encoder.encode(brand, forKey:"brand")
        encoder.encode(serialNo, forKey:"serialNo")
        encoder.encode(model, forKey:"model")
        encoder.encode(version, forKey:"version")
        encoder.encode(maxSpeed, forKey:"maxSpeed")
        encoder.encode(limitSpeed, forKey:"limitSpeed")
        encoder.encode(alarmSpeed, forKey:"alarmSpeed")
        encoder.encode(notifySpeed, forKey:"notifySpeed")
        encoder.encode(batteryAlarm, forKey:"batteryAlarm")
        encoder.encode(notifyBattery, forKey:"notifyBattery")
        encoder.encode(totalDistance, forKey:"totalDistance")
        
        encoder.encode(nruns, forKey:"nruns")
        encoder.encode(distance_sum_xy, forKey:"distance_sum_xy")
        encoder.encode(distance_sum_x2, forKey:"distance_sum_x2")
        encoder.encode(speed_sum_xy, forKey:"speed_sum_xy")
        encoder.encode(distance_coef, forKey:"distance_coef")
        encoder.encode(speed_coef, forKey:"speed_coef")
        encoder.encode(enableCorrections, forKey:"enableCorrections")
        
    }
    public func getKey() -> String{
        
        return uuid
        
    }

    //MARK: Some specific functions 
    
    public func getSpeedCorrection() -> Double{
        
        return enableCorrections ? speed_coef : 1.0
    }
    
    public func getDistanceCorrection() -> Double{
        
        return enableCorrections ? distance_coef : 1.0
    }
    
    func getAllRuns() -> [URL]{
        
        var runs : [URL] = []
        

                if let docs = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last{

                
                    let mgr = FileManager()
            
                    let enumerator = mgr.enumerator(at: docs, includingPropertiesForKeys: nil, options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants]) { (URL, Error) -> Bool in
                
                        let err = Error as NSError
                        //AppDelegate.debugLog("Error enumerating files %@", err.localizedDescription)
                        return false
                    }
                    
                    if let arch = enumerator{
                        
                        for item in arch  {
                            
                            if let url = item as? URL{
                                
                                if url.pathExtension  == "9bm"{
                                    runs.append( url)
                                }
                            }
                            
                        }
                    }
                   
                }
        
        
        return runs
        
    }
    
    //MARK: Calibration
    /**
        Computes distance adjust with GPS data
        sets nruns, sum_xy, sum_x2 and coef values in wheel
 
    */
    
    public func resetCalibration(){
        
        nruns = 0
        distance_sum_xy = 1.0
        distance_sum_x2 = 1.0
        speed_sum_xy = 1.0
        speed_coef = 1.0
        distance_coef = 1.0
        
    }
    
    public func recomputeAdjust(progressItem: UIProgressView?){
        
        nruns = 0
        distance_sum_xy = 0.0
        distance_sum_x2 = 0.0
        speed_sum_xy = 0.0
        
        
        
        // Get all packages in the directory
        
        let track  = WheelTrack()
        
        let runs = getAllRuns()
        
        let n  : Float = Float(runs.count) * 2.0
        
        var i : Float = 0.0
        
        if let pr = progressItem{
            DispatchQueue.main.sync(execute: {
                pr.setProgress(0.0, animated: false)
            })
        }
        for url in runs{
            
            i = i + 1.0
            
            if let pr = progressItem{
                DispatchQueue.main.sync(execute: {
                pr.setProgress(i/n, animated: true)
            })
            }

            
            track.loadPackage(url)
            
            // Now we have summary data loaded :
            
            if track.getUUID() == uuid {
                let dGPS = track.getCurrentValueForVariable(.DistanceGPS)
                let dWheel = track.getCurrentValueForVariable(.Distance)
                let (_, _, _, dSpeed) = track.getCurrentStats(.Speed)
                
                if dWheel > 0.0 && fabs(dGPS - dWheel)/dWheel  < 0.3 && fabs(dSpeed - dWheel)/dWheel < 0.3{
                    nruns += 1
                    distance_sum_xy +=  dGPS * dWheel
                    distance_sum_x2 += pow(dGPS, 2.0)
                    speed_sum_xy += dGPS * dSpeed
                }
            }
         }
        
        if distance_sum_xy != 0.0 {
            distance_coef = (distance_sum_x2 / distance_sum_xy)
        } else {
            distance_coef = 1.0
        }
        
        if speed_sum_xy != 0.0 {
            speed_coef = (distance_sum_x2 / speed_sum_xy)
        } else {
            speed_coef = 1.0
        }
        
        //AppDelegate.debugLog("Runs %d dCoef %f sCoef %f", nruns, distance_coef, speed_coef)
        
        nruns = 0
        distance_sum_xy = 0.0
        distance_sum_x2 = 0.0
        speed_sum_xy = 0.0

        
        // That is first run now we redoit but just with tracks within 10% of theoretical value
        
        for url in runs{
            
            i = i + 1.0
            
            if let pr = progressItem{
                DispatchQueue.main.sync(execute: {
                    pr.setProgress(i/n, animated: true)
                })
            }

            
            track.loadPackage(url)
            
            // Now we have summary data loaded :
            
            if track.getUUID() == uuid {
                let dGPS = track.getCurrentValueForVariable(.DistanceGPS)
                let dWheel = track.getCurrentValueForVariable(.Distance)
                let (_, _, _, dSpeed) = track.getCurrentStats(.Speed)
                
                let predWheel = dGPS / distance_coef
                let predSpeed = dGPS / speed_coef
                
                
                if dWheel > 0.0 && fabs(predWheel - dWheel)/dWheel  < 0.1 && fabs(predSpeed - dSpeed)/dSpeed < 0.1{
                    nruns += 1
                    distance_sum_xy +=  dGPS * dWheel
                    distance_sum_x2 += pow(dGPS, 2.0)
                    speed_sum_xy += dGPS * dSpeed
                }
            }
        }

        if distance_sum_xy != 0.0 && distance_sum_x2 != 0.0{
            distance_coef = (distance_sum_x2 / distance_sum_xy)
        } else {
            distance_sum_xy = 1.0
            distance_sum_x2 = 1.0
            distance_coef = 1.0
        }
        
        if speed_sum_xy != 0.0 && distance_sum_x2 != 0.0{
            speed_coef = (distance_sum_x2 / speed_sum_xy)
        } else {
            distance_sum_x2  = 1.0
            speed_sum_xy = 1.0
            speed_coef = (distance_sum_x2 / speed_sum_xy)

        }
        
       // AppDelegate.debugLog("Runs %d dCoef %f sCoef %f", nruns, distance_coef, speed_coef)
      
    }
    
    // Check to update only if data are in the 10% range of predicted. So exceptional data will get forgotten.
    // Of course it may be better done.
    // Also we supose that :
    //
    //  GPS data is only available when GPS is functioning
    //  Wheel data is always available
    //
    
    public func updateRun(_ track : WheelTrack){
        
        
        if track.getUUID() == uuid && enableCorrections {
            let dGPS = track.getCurrentValueForVariable(.DistanceGPS)
            let dWheel = track.getCurrentValueForVariable(.Distance)
            let (_, _, _, dSpeed) = track.getCurrentStats(.Speed)
            
            // Just a test so data are between a 10% of the already predicted value. We want the system to adjust, not reverse all data
            
            let predWheel = dGPS / distance_coef
            let predSpeed = dGPS / speed_coef
            
            
            if (dWheel > 0.0 && fabs(predWheel - dWheel)/dWheel  < 0.1 && fabs(predSpeed - dSpeed)/dWheel < 0.1) || nruns == 0{
                nruns += 1
                distance_sum_xy +=  dGPS * dWheel
                distance_sum_x2 += pow(dGPS, 2.0)
                speed_sum_xy += dGPS * dSpeed
            }
            
            
            if distance_sum_xy != 0.0 && distance_sum_x2 != 0.0{
                distance_coef = (distance_sum_x2 / distance_sum_xy)
            } else {
                distance_sum_xy = 1.0
                distance_sum_x2 = 1.0
                distance_coef = 1.0
            }
            
            if speed_sum_xy != 0.0 && distance_sum_x2 != 0.0{
                speed_coef = (distance_sum_x2 / speed_sum_xy)
            } else {
                distance_sum_x2  = 1.0
                speed_sum_xy = 1.0
                speed_coef = (distance_sum_x2 / speed_sum_xy)
                
            }
            
        }
    }
}



