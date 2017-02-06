//
//  UnitsManager.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 31/1/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation


public class UnitManager {

    
    static let sharedInstance = UnitManager()
   
    
    var locale = Locale.current
    //var locale = Locale(identifier: "en-US")
    var heightConverter = 1.0           // m = 1.0, ft = 3.281
    var shortDistanceConverter = 1.0    // m = 1.0 yd = 1.094
    var longDistanceConverter = 1.0     // km = 1.0 mi = 0.6214

    
    var heightUnit = "m"
    var shortDistanceUnit = "m"
    var longDistanceUnit = "km"
    var temperatureUnit = "ºC"
    
    
    init(){
        updateScaleFactors()
    }
    
    func setLocale(_ l : Locale ){
        locale = l
        updateScaleFactors()
    }
    
    func updateScaleFactors(){
        if locale.usesMetricSystem {
            heightConverter = 1.0
            shortDistanceConverter = 1.0
            longDistanceConverter = 1.0
            heightUnit = "m"
            shortDistanceUnit = "m"
            longDistanceUnit = "km"
            temperatureUnit = "ºC"
        }else{
            heightConverter = 3.281
            shortDistanceConverter = 1.094
            longDistanceConverter = 0.6214
            heightUnit = "ft"
            shortDistanceUnit = "yd"
            longDistanceUnit = "mi"
            temperatureUnit = "ºF"
        }
    }

    // Input is in m output has 0 or 2 decs
    
    func formatDistance(_ d : Double) -> String{
        
             if (d / 1000.0 * longDistanceConverter) < 1.0 {
                return String(format: "%0.0f %@", d * shortDistanceConverter, shortDistanceUnit)
            } else {
                
                return String(format: "%0.2f %@", d / 1000.0 * longDistanceConverter, longDistanceUnit)
            }
        
    }
    
    // Input is in m
    
    func formatHeight(_ d : Double) -> String {
        
        return String(format: "%0.0f %@", d * heightConverter, heightUnit)
    }
    
    // Input is in m/s -> km/h or mi/h (2 decs)
    
    func formatSpeed(_ d : Double) -> String {
        
        return String(format: "%0.2f %@/h", d * 3.6 * longDistanceConverter, longDistanceUnit)
    }
    
    func formatTemperature(_ d : Double) -> String{
        
        var cd = d
        
        if !locale.usesMetricSystem {
            cd = d * 1.8 + 32.0   // Convert to Farenheit
        }
        
        return String(format: "%0.1f %@", cd, temperatureUnit)
    }
    
    func convertShortDistance(_ d : Double) -> Double {
        return d * shortDistanceConverter
    }
    
    func convertLongDistance(_ d : Double) -> Double {
        return d * longDistanceConverter
    }
    
    func convertHeight(_ d : Double) -> Double {
        return d * heightConverter
    }
    
    // Entran m/s -> km/h o yd/h
    func convertSpeed(_ d : Double ) -> Double {
        return d * 3.6 * longDistanceConverter
    }

    func convertTemperature(_ d : Double) -> Double{
        
        var cd = d
        
        if !locale.usesMetricSystem {
            cd = d * 1.80 + 32.0   // Convert to Farenheit
        }
        
        return cd
    }

}

    
    
    
 
