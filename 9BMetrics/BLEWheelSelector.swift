//
//  BLEWheelSelector.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 18/9/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

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
        adapters.append(adapter)
    }
    
    func getAdapter(wheelServices : [String : BLEService]) -> BLEWheelAdapterProtocol?{
        
        for adapter in adapters {
            if adapter.isComptatible(services: wheelServices){
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
