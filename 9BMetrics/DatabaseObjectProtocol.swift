//
//  DatabaseObjectProtocol.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 6/2/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation
import UIKit


public protocol DatabaseObjectProtocol {
    
    associatedtype KeyType : Hashable
    
    func initWithCoder(_ decoder : NSCoder)
    func encodeWithCoder(_ encoder: NSCoder)
    func getKey() -> KeyType
}
