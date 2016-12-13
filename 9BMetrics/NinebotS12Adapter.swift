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

import Foundation
import CoreBluetooth

class NinebotS12Adapter : BLENinebotOneAdapter {
    
    
    //MARK: Sending Requests
    
    override func sendData(_ connection : BLEMimConnection, message : BLENinebotMessage?){
        
        
        if self.headersOk {  // Get normal data
            
            
            for (op, l) in listaOpFast{
                let message = BLENinebotMessage(com: op, dat:[ l * 2] )
                if let dat = message?.toNSData(){
                    connection.writeValue("FEC7", data:dat)
                }
            }
            
            let (op, l) = listaOp[contadorOp]
            contadorOp += 1
            
            if contadorOp >= listaOp.count{
                contadorOp = 0
            }
            
            let message = BLENinebotMessage(com: op, dat:[ l * 2] )
            
            if let dat = message?.toNSData(){
                connection.writeValue("FEC7", data:dat)
            }
        }else {    // Get One time data (S/N, etc.)
            
            
            var message = BLENinebotMessage(com: UInt8(16), dat: [UInt8(22)])
            if let dat = message?.toNSData(){
                connection.writeValue("FEC7", data:dat)
            }
            
            // Get riding Level and max speeds
            
            message = BLENinebotMessage(com: UInt8(BLENinebot.kAbsoluteSpeedLimit), dat: [UInt8(4)])
            
            if let dat = message?.toNSData(){
                connection.writeValue("FEC7", data:dat)
            }
            
            message = BLENinebotMessage(com: UInt8(BLENinebot.kvRideMode), dat: [UInt8(2)])
            
            if let dat = message?.toNSData(){
                connection.writeValue("FEC7", data:dat)
            }
            
        }
    }
    
    // MARK: NSOperationSupport
    
    override func injectRequest(_ tim : Timer){
        
        if let connection = tim.userInfo as? BLEMimConnection {
            self.sendNewRequest(connection)
        }
    }
    
    override func sendNewRequest(_ connection : BLEMimConnection){
        
        let request = BLERequestOperation(adapter: self, connection: connection)
        
        if let q = self.queryQueue{
            q.addOperation(request)
        }
    }
    
    

//MARK: BLEWheelAdapterProtocol Extension


    override func wheelName() -> String {
        return "Ninebot S1/S2"
    }
    
    override func isComptatible(services : [String : BLEService]) -> Bool{
        
        
        // De moment deixem el warning per si hem d'analitzar millor.
        
        if let srv = services["FEE7"]{
            if let _ = srv.characteristics["FEC7"], let _ = srv.characteristics["FEC8"], let _ = srv.characteristics["FEC9"] {
                return true
                
            }
        }
        
        return false
    }
    
    
    override func startRecording(){
        headersOk = true
        contadorOp = 0
        contadorOpFast = 0
        buffer.removeAll()
        if let qu = queryQueue {
            qu.cancelAllOperations()
        }
        
    }
    
    override func stopRecording(){
        headersOk = false
        contadorOp = 0
        contadorOpFast = 0
        buffer.removeAll()
        if let qu = queryQueue {
            qu.cancelAllOperations()
        }
        if let tim  = sendTimer {
            tim.invalidate()
            sendTimer = nil
        }
    }
    
    override func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        // OK, subscribe to characteristif FFE1
        
        connection.subscribeToChar("FEC8")
        
        self.contadorOp = 0
        self.headersOk = false
        
        self.sendNewRequest(connection)
        
        
        
        // Just to be sure we start another timer to correct cases where we loose all requests
        // Will inject one request every timerStep
        
        self.sendTimer = Timer.scheduledTimer(timeInterval: timerStep, target: self, selector:#selector(BLENinebotOneAdapter.injectRequest(_:)), userInfo: connection, repeats: true)
        
        
    }
    
    
    
    override func getName() -> String{
        return "Ninebot S1/S2"
    }
    
    override func getVersion() -> String{
        
        let clean = values[BLENinebot.kVersion] & 4095
        
        let v0 = clean / 256
        let v1 = (clean - (v0 * 256) ) / 16
        let v2 = clean % 16
        
        return String(format: "%d.%d.%d",v0, v1, v2)
    }
    
    override func getSN() -> String{
        
        if !self.checkHeaders(){
            return ""
        }
        
        var no = ""
        
        
        
        for i in 16 ..< 23{
            
            
            let v = values[i]
            
            
            let v1 = v % 256
            let v2 = v / 256
            
            let ch1 = Character(UnicodeScalar(v1)!)
            let ch2 = Character(UnicodeScalar( v2)!)
            
            no.append(ch1)
            no.append(ch2)
        }
        
        return no
    }
    override func getRidingLevel() -> Int{
        return 0
    }
    
    override func getMaxSpeed() -> Double {
        return 20.0
    }

    
    override func setDefaultName(_ name : String){
        self.name = name
    }
    override func setLimitSpeed(_ speed : Double){
    }
}


