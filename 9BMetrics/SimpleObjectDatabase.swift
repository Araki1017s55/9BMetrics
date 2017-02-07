//
//  SimpleObjectDatabase.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 6/2/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation


public class SimpleObjectDatabase<K : Hashable, T:DatabaseObjectProtocol>{
    
    var database : [K:T] = [:]
    var url : URL?
    
    
    init(){
        
    }
    
    init(url ur: URL){
        url = ur
        read()
    }
    
    func save(){
        
        guard url != nil else {return}
        
        let success = NSKeyedArchiver.archiveRootObject(database, toFile: url!.path)
        if !success {
            // Throw some error
        }
        
        
    }
    
    func read(){
        
        guard url != nil else {return}
        let fm = FileManager.default
        
        
        if fm.fileExists(atPath: url!.path){
            if let dat = NSKeyedUnarchiver.unarchiveObject(withFile:url!.path) as? [K : T]{
                database = dat
            }
        }
        
    }
    
    func getObject(forKey key :K) -> T?{
        
        return database[key]
    }
    
    func addObject(_ object: T){
        
        if let key : K = object.getKey() as? K {
            database[key] = object
            save()
        }
    }
    
    func addObjectWithoutSaving(_ object: T){
        if let key : K = object.getKey() as? K {
            database[key] = object
        }
    }
    
    func removeObject(_ object : T){
        
        if let key : K = object.getKey() as? K {
            database.removeValue(forKey: key)
            save()
        }
    }
    
    func count() -> Int{
        return database.count
    }
    
    func removeAll() {
        database.removeAll()
    }
    
}
