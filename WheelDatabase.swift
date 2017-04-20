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
    
    static let sharedInstance = WheelDatabase()
    
    var filename = "wheels"

    
    override init(){
        // Load archive
        if let dele =  UIApplication.shared.delegate as? AppDelegate{
            if let docs = dele.applicationDocumentsDirectory(){
                let url = docs.appendingPathComponent(filename)
                
                super.init(url: url)
                
            } else {
                super.init()
            }
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
    
     func getWheelFromUUID(uuid : String) -> Wheel? {
        return getObject(forKey: uuid)
    }
    
    func setWheel(wheel : Wheel){
        addObject(wheel)
    }
    
    func removeWheel(wheel : Wheel){
        
        removeObject(wheel)
    }
    
    
    func updatePassword(_ password : String, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.password = password
            database[uuid] = wh
            save()
        }
    }
    
    func updateAlarmSpeed(_ speed : Double, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.alarmSpeed = speed
            database[uuid] = wh
            save()
        }
    }
    
    func updateSerialNumber(_ sn : String, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.serialNo = sn
            database[uuid] = wh
            save()
        }
    }
    
    
    func updateModel(_ model : String, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.model = model
            database[uuid] = wh
            save()
        }
    }

    func updateVersion(_ version : String, uuid: String){
        
        let wheel = getWheelFromUUID(uuid: uuid)
        if let wh = wheel {
            wh.version = version
            database[uuid] = wh
            save()
        }
    }
    
}
