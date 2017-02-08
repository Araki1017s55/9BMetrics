//
//  WheelTrackSummary.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 7/2/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation
import UIKit

class WheelTrackSummary : NSObject, DatabaseObjectProtocol {
    
    typealias KeyType = String
    

    var name : String = ""
    var adapter : String = ""
    var date : Date = Date()
    var distance : Double = 0.0
    var duration : Double = 0.0
    var pathname : String = ""
    
    
    func initWithCoder(_ decoder : NSCoder){
        
        
        self.name = decoder.decodeObject(forKey: "name") as? String ?? ""
        self.adapter = decoder.decodeObject(forKey: "adapter") as? String ?? ""
        self.date = Date(timeIntervalSince1970: decoder.decodeDouble(forKey: "date"))
        self.distance = decoder.decodeDouble(forKey: "distance")
        self.duration = decoder.decodeDouble(forKey: "duration")
        self.pathname = decoder.decodeObject(forKey: "pathname") as? String ?? ""
        
  
    }
    
    func encodeWithCoder(_ encoder: NSCoder){
        
        encoder.encode(name, forKey:"name")
        encoder.encode(adapter, forKey:"adapter")
        encoder.encode(date.timeIntervalSince1970, forKey:"date")
        encoder.encode(distance, forKey:"distance")
        encoder.encode(duration, forKey:"duration")
        encoder.encode(pathname, forKey:"pathname")
        
        
    }
    
    func getKey() -> KeyType {
        return pathname
    }
    
    func getURL() -> URL?{
    
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {return nil}
        
        guard let docsURL = delegate.applicationDocumentsDirectory() else {return nil}
        
        return docsURL.appendingPathComponent(pathname)
    }
   
    
}
