//
//  WheelSelectorDelegate.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 27/1/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation
import GyrometricsDataModel

protocol WheelSelectorDelegate {
    
    func selectedWheel(_ wheel : Wheel?)
}
