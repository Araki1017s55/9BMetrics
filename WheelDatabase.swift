//
//  WheelDatabase.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 1/1/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation
import UIKit

public class WheelDatabase :  SimpleObjectDatabase<String, Wheel> {
    
    public static let sharedInstance = WheelDatabase()
    
    var filename = "wheels"

    
    override init(){
        // Load archive
 
            if let docs = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last{
                let url = docs.appendingPathComponent(filename)
                
                super.init(url: url)
                
            } else {
                super.init()
            }

    }
    
//    func read(){
//        let fm = FileManager.default
//        if let url = WheelDatabase.buildUrl(filename) {
//            if fm.fileExists(atPath: url.path){
//                if let dat = NSKeyedUnarchiver.unarchiveObject(withFile:url.path) as? [String : Wheel]{
//                    database = dat
//                }
//            }
//        }
//    }
//    func save(){
//         if let url = WheelDatabase.buildUrl(filename) {
//            
//            let path = url.path
//            let success = NSKeyedArchiver.archiveRootObject(database, toFile: path)
//            
//            if !success {
//               AppDelegate.debugLog("Error al gravar diccionari")
//            }
//        }
//    }
    
     public func getWheelFromUUID(uuid : String) -> Wheel? {
        return getObject(forKey: uuid)
    }
    
    public func setWheel(wheel : Wheel){
        addObject(wheel)
    }
    
    public func removeWheel(wheel : Wheel){
        
        removeObject(wheel)
    }
    
    
    public func updatePassword(_ password : String, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.password = password
            database[uuid] = wh
            save()
        }
    }
    
    public func updateAlarmSpeed(_ speed : Double, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.alarmSpeed = speed
            database[uuid] = wh
            save()
        }
    }
    
    public func updateSerialNumber(_ sn : String, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.serialNo = sn
            database[uuid] = wh
            save()
        }
    }
    
    
    public func updateModel(_ model : String, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.model = model
            database[uuid] = wh
            save()
        }
    }

    public func updateVersion(_ version : String, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.version = version
            database[uuid] = wh
            save()
        }
    }
    
}
