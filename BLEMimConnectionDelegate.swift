//
//  BLEMimConnectionDelegate.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 13/9/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import Foundation
import CoreBluetooth


protocol BLEMimConnectionDelegate : BLENinebotConnectionDelegate {
    
    
    func deviceAnalyzed( _ peripheral : CBPeripheral, services : [String : BLEService])    
}
