//
//  WheelDatabase.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 1/1/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation
import UIKit

public class WheelDatabase {
    
    static let sharedInstance = WheelDatabase()
    
    var database : [String : Wheel] = [:]
    
    var filename = "wheels"
    var databaseUrl : URL?

    
    init(){
        
        read()
    }
    
    func read(){
        let fm = FileManager.default
        if let url = WheelDatabase.buildUrl(filename) {
            if fm.fileExists(atPath: url.path){
                if let dat = NSDictionary.init(contentsOf: url) as? [String : Wheel]{
                    database = dat
                }
            }
        }
    }
    func save(){
        let dat = database as NSDictionary
        if let url = WheelDatabase.buildUrl(filename) {
            dat.write(to: url, atomically: true)
        }
    }
    
    static func buildUrl(_ filename : String) -> URL?{
        
        if let dele =  UIApplication.shared.delegate as? AppDelegate{
            if let docs = dele.localApplicationDocumentsDirectory(){
                let url = docs.appendingPathComponent(filename)
                return url
            }
        }
        return nil
        
    }
    func getWheelFromUUID(uuid : String) -> Wheel? {
        return database[uuid]
    }
    
    func setWheel(wheel : Wheel){
        database[wheel.uuid] = wheel
        save()
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
