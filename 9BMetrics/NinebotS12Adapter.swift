//
//  BLENinebotOneAdapter.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 4/5/16.
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
//
// NB S2 tenim

//
//  Service FEE7 Char FEC7 (w)
// Service 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
//      Chars 6E400003-B5A3-F393-E0A9-E50E24DCCA9E (n)
//            6E400002-B5A3-F393-E0A9-E50E24DCCA9E (wx)
//  Service ???? Char FEC8(i)
//



import Foundation
import CoreBluetooth


class NinebotS12Adapter : BLENinebotOneAdapter {
    
    // Service 6E400001-B5A3-F393-E0A9-E50E24DCCA9E (Nordic)
    
    
    override init(){
        super.init()
        readChar = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"  // FEC8  //
        writeChar = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"  // FEC7
    }
    

//MARK: BLEWheelAdapterProtocol Extension


    override func wheelName() -> String {
        return "Ninebot S1/S2"
    }
    
    override func isComptatible(services : [String : BLEService]) -> Bool{
        
        
        // Atenció, l'ordre es significatiu. Probablement podem incorporar el normal.
        
        if let srv = services["FEE7"]{      // Tambe podria ser 0x0001 i les readChar i writeChar
            if let _ = srv.characteristics["FEC7"], let _ = srv.characteristics["FEC8"], let _ = srv.characteristics["FEC9"] {
                
                readChar = "FEC8"
                writeChar = "FEC7"
                return true
                
            }
        }
        else if let srv = services["6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]{
            if let _ = srv.characteristics["6E400003-B5A3-F393-E0A9-E50E24DCCA9"], let _ = srv.characteristics["6E400002-B5A3-F393-E0A9-E50E24DCCA9E"], let _ = srv.characteristics["FEC9"] {
                
                readChar = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
                writeChar = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
                return true
                
            }
        }
        return false
    }
    
 }


