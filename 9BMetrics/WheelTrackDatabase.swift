//
//  WheelTrackDatabase.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 2/2/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation
import Foundation
import UIKit

public class WheelTrackDatabase {
    
    static let sharedInstance = WheelTrackDatabase()

    var database : [String : Wheel] = [:]
    
    var filename = "trackDatabase"
    var databaseUrl : URL?

    
    init(){
        
        // Load archive
        
        
    }
    
    func read(){
        let fm = FileManager.default
        if let url = buildUrl(filename) {
            if fm.fileExists(atPath: url.path){
                if let dat = NSKeyedUnarchiver.unarchiveObject(withFile:url.path) as? [String : Wheel]{
                    database = dat
                }
            }
        }
    }
    func save(){
        if let url = WheelDatabase.buildUrl(filename) {
            
            let path = url.path
            let success = NSKeyedArchiver.archiveRootObject(database, toFile: path)
            
            if !success {
                AppDelegate.debugLog("Error al gravar diccionari")
            }
        }
    }
    
    func buildUrl(_ filename : String) -> URL?{
        
        if let dele =  UIApplication.shared.delegate as? AppDelegate{
            if let docs = dele.localApplicationDocumentsDirectory(){
                let url = docs.appendingPathComponent(filename)
                return url
            }
        }
        return nil
        
    }
   
    func buildArchive(){
        
        
    }
    
    
    func addToArchive(_ track : WheelTrack){
        
        
        
        
    }
    
    

}
