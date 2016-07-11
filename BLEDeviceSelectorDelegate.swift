//
//  BLEDeviceSelectorDelegate.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 25/6/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import Foundation
import CoreBluetooth


protocol BLEDeviceSelectorDelegate {
    func connectToPeripheral(peripheral : CBPeripheral)

}