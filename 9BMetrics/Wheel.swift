//
//  Wheel.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 1/1/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation

public class Wheel {
    
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
    
    
    init(uuid : String, name : String){
        self.uuid = uuid
        self.name = name

    }
        
}
