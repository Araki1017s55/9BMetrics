//
//  WheelTrackSummary.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 7/2/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation
import UIKit

public class WheelTrackSummary : NSObject, DatabaseObjectProtocol {
    
    public typealias KeyType = String
    

    public var name : String = ""
    public var adapter : String = ""
    public var date : Date = Date()
    public var distance : Double = 0.0
    public var duration : Double = 0.0
    public var pathname : String = ""
    
    
    public func initWithCoder(_ decoder : NSCoder){
        
        
        self.name = decoder.decodeObject(forKey: "name") as? String ?? ""
        self.adapter = decoder.decodeObject(forKey: "adapter") as? String ?? ""
        self.date = Date(timeIntervalSince1970: decoder.decodeDouble(forKey: "date"))
        self.distance = decoder.decodeDouble(forKey: "distance")
        self.duration = decoder.decodeDouble(forKey: "duration")
        self.pathname = decoder.decodeObject(forKey: "pathname") as? String ?? ""
        
  
    }
    
    public func encodeWithCoder(_ encoder: NSCoder){
        
        encoder.encode(name, forKey:"name")
        encoder.encode(adapter, forKey:"adapter")
        encoder.encode(date.timeIntervalSince1970, forKey:"date")
        encoder.encode(distance, forKey:"distance")
        encoder.encode(duration, forKey:"duration")
        encoder.encode(pathname, forKey:"pathname")
        
        
    }
    
    public func getKey() -> KeyType {
        return pathname
    }
    
    public func getURL() -> URL?{
    
         
        guard let docsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last else {return nil}
        
        return docsURL.appendingPathComponent(pathname)
    }
   
    
}
