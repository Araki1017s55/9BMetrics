//
//  Wheel.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 1/1/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation

public class Wheel : NSObject {
    
    var uuid : String = ""
    var name : String = ""
    var password : String  = "000000"
    var brand : String = "Ninebot"
    var serialNo : String = "NOE2"
    var model : String = "Ninebot One E+"
    var version : String = "1.1.1"
    var maxSpeed : Double = 8.33    // Max speed m/s
    var limitSpeed : Double = 8.33  // Limited speed (from the wheel)
    var alarmSpeed : Double = 5.56  // Applcation Alarm Speed 
    var notifySpeed : Bool = false
    var batteryAlarm : Double = 20 // Battery alarm. 20%
    var notifyBattery : Bool = true
    var totalDistance : Double = 0.0    // Just to get the total distance. Updated with every run
    
    
    init(uuid : String, name : String){
        //super.init()
        self.uuid = uuid
        self.name = name
    }
    
    func initWithCoder(_ decoder : NSCoder){
        
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
        
        
        
        
    }
    
    func encodeWithCoder(_ encoder: NSCoder){
        
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
       
    }
    
    
    
    
}
