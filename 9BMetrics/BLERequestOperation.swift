//
//  BLERequestOperation.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 17/3/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit

class BLERequestOperation: NSOperation {
    
    let client : BLESimulatedClient
    
    init(cliente : BLESimulatedClient) {
        self.client = cliente
    }
    
    override func main() {
   
        if self.cancelled {
            return
        }
      
        if client.connected  {
            client.sendData()
        }
     }
}
