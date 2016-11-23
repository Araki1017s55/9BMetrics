//
//  BLEWheelSelector.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 18/9/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//( at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

class BLEWheelSelector {
    
    static let sharedInstance : BLEWheelSelector = {
        let instance = BLEWheelSelector()
        
        return instance
    }()
    
    var adapters : [BLEWheelAdapterProtocol] = []

    
    init(){

    }
    
    func registerAdapter(_ adapter : BLEWheelAdapterProtocol){
        AppDelegate.debugLog("Registered adapter for %@", adapter.wheelName())
        adapters.append(adapter)
    }
    
    func getAdapter(wheelServices : [String : BLEService]) -> BLEWheelAdapterProtocol?{
        
        for adapter in adapters {
            if adapter.isComptatible(services: wheelServices){
                AppDelegate.debugLog("Recognized  Wheel as %@", adapter.wheelName())
                return adapter
            }
        }
        
        return nil
    }
    
    func wheelKind(wheelServices : [String : BLEService]) -> String{
        for adapter in adapters {
            if adapter.isComptatible(services: wheelServices){
                return adapter.wheelName()
            }
        }
        
        return "Unknown"
    }
    
    
}
