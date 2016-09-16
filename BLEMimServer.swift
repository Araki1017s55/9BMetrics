//
//  BLESimulatedServer.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
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


import UIKit
import CoreBluetooth

class BLEMimServer: NSObject, CBPeripheralManagerDelegate {
    
    let manager : CBPeripheralManager
    var transmiting = false
    var scanning = false
    
    var serviceId = "FFE0"
    var serviceName = "HMSoft"
    var charId = "FFE1"
    
    
    var caracteristicas : [String : CBMutableCharacteristic] = [:]
    var servei : CBMutableService?
    
    var services : [String : BLEService] = [:]
    
    weak var delegate : BLENinebotServerDelegate?
    
    override init() {
        
        self.manager = CBPeripheralManager()
        super.init()
        self.manager.delegate = self
        
    }
    
    func lookupChar(uuid : String) -> CBMutableCharacteristic? {
        
             return caracteristicas[uuid]
    }
   

    
    // MARK: PeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral : CBPeripheralManager){
        
        switch(peripheral.state){
            
        case .PoweredOn: // Configurem el servei
           // self.buildService()
            //self.startTransmiting()
            break
            
        default:        // Powerdown
            
            self.transmiting = false
            peripheral.stopAdvertising()
        }
        
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        
        if let del = self.delegate {
            
            del.remoteDeviceSubscribedToCharacteristic(characteristic, central: central)
        }
        
        
        
        // Build a NSData amb la resposta. Quina es????
        
        //       let data = NSData(bytes: [0x55, 0xAA, 4, 9, 1, 25, 0x76, 6, 0x50, 0xff] as [UInt8], length: 10)
        
        //        self.manager.updateValue(data, forCharacteristic: self.caracteristica!, onSubscribedCentrals: nil);
        
        
        
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        
        if let del = self.delegate {
            
            del.remoteDeviceUnsubscribedToCharacteristic(characteristic, central: central)
        }
        
        
    }
    
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest){
        
        if let dele = self.delegate{
            dele.readReceived(request.characteristic)
        }
        
        peripheral.respondToRequest(request, withResult: CBATTError.Success)
        
    }
    
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        
        for request in requests {
            let value = request.value
            
            if let data = value {
                
                if let dele = self.delegate{
                    dele.writeReceived(request.characteristic, data: data)
                    
                }
            }
            peripheral.respondToRequest(request, withResult: CBATTError.Success)
        }
    }
    
    
    
    
    //MARK: Auxiliar
    
    func updateValue(uuid: String, data : NSData){
        
         if let car = lookupChar(uuid){
            
            self.manager.updateValue(data, forCharacteristic: car, onSubscribedCentrals: nil);
        }
        
    }
    
    func buildService(){
        
        caracteristicas.removeAll()
        
        for (_, srv ) in self.services {
            
            if let sv = srv.service {
                
                
                let primary = sv.isPrimary
                if primary {
                    self.serviceId = srv.id
                }
                let id = CBUUID(string: srv.id)
                let servei = CBMutableService(type: id, primary: primary)
                
                // Build chars array
                
                var chars : [CBMutableCharacteristic] = []
                
                for (_, ch) in srv.characteristics{
                    
                    if let cha = ch.characteristic{
                        let caracteristica = CBMutableCharacteristic(type: CBUUID(string: ch.id), properties: cha.properties, value: nil, permissions: [CBAttributePermissions.Readable,CBAttributePermissions.Writeable])
                        caracteristica.descriptors = cha.descriptors
                        chars.append(caracteristica)
                        
                        caracteristicas[ch.id] = caracteristica
                    }
                    
                }
                
                servei.characteristics = chars
                self.manager.addService(servei)
                
            }
         }
        
     }
    func startTransmiting(){
        
        _ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(BLEMimServer.checkState(_:)), userInfo: nil, repeats: false)
        
    }
    
    func checkState(tim : NSTimer){
        
        tim.invalidate()
        
        if self.manager.state == .PoweredOn {
            startTransmitingReal()
        }else {
            _ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(BLEMimServer.checkState(_:)), userInfo: nil, repeats: false)
        }
        
    }
    func startTransmitingReal(){
        
        
        self.buildService()
    
        let dict : Dictionary = [CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: self.serviceId)],
                                 CBAdvertisementDataLocalNameKey : "NOE002"]
        
        self.manager.startAdvertising(dict)
        self.transmiting = true
        
    }
    
    func stopTransmiting(){
        
        self.manager.stopAdvertising()
        self.transmiting = false
        
    }
}
