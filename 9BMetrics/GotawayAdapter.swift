//
//  GotawayAdapter.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 3/10/16.
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
import GyrometricsDataModel

class GotawayAdapter : NSObject {
    
    var headersOk = false
    
    var buffer : [UInt8] = []
    var voltageArray : [Double] = []
    var acumVoltage : Double = 0.0
    
    let NVoltageSamples = 10
    
    var name = "Gotway"
    var serial = "12345"
    
    var wheel : Wheel?
    
    var startDistance : Double?
    
    
    // Called when lost connection. perhaps should do something. If not forget it
    
    
    // Data Received. Analyze, extract, convert and prosibly return a dictionary of characteristics and values
    
    
    // Called by connection when we got device characteristics
    
    override init(){
        super.init()
        
    }
     
    //MARK: Receiving Data. Append data to buffer
    
    func appendToBuffer(_ data : Data){
        
        let count = data.count
        var buf = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buf, length:count * MemoryLayout<UInt8>.size)
        buffer.removeAll()
        buffer.append(contentsOf: buf)
    }
    
    // Here we process received information.
    // We maintain a buffer (buffer) and data is appended in appendToBuffer
    // as each block is received. Logical Data may span more than one block and not be aligned.
    //
    //
    //  So we call procesaBuffer to extract any posible data. It is returned as an array of
    //  3 values, the variable, the date and the value all aready converted to ggeneric values
    // and SI units
    
    // Gotaway sends buffers containing all the information in one buffer
    
    func procesaBuffer(_ connection: BLEMimConnection) -> [(WheelTrack.WheelValue, Date, Double)]?
    {
        // Wait till header. We wait till we find a 0x55
        
        
        var outarr : [(WheelTrack.WheelValue, Date, Double)] = []
        
        while buffer.count > 0 && buffer[0] != 0x55 {
            buffer.removeFirst()
        }
        
        // Following character must be 0xaa, if not is noise
        
        
        if buffer.count < 10{    // Wait for more data
            return outarr
        }
        
        if buffer[1] != 0xAA {  // Fals header. continue cleaning
            
            return outarr
        }
        
        let date = Date()
//        let block = Array(buffer)
        // We have 20 bytes and 10 bytes buffers
        
        switch(buffer.count){
            
        case 10:
            
            
            var  totalDistance = Double( (Int(buffer[2]) * 256 + Int(buffer[3]))*65536)
            totalDistance += Double((Int(buffer[4]) * 256 + Int(buffer[5])))
            outarr.append((WheelTrack.WheelValue.AcumDistance, date, totalDistance))
            
            if let wh = self.wheel {
                wh.totalDistance = totalDistance
                WheelDatabase.sharedInstance.setWheel(wheel: wh)
            }

            
            buffer.removeAll()
            break
            
        case 20:
                var speed = Double(Int(buffer[4]) * 256 + Int(buffer[5]))
                
                if speed >= 32768.0  {
                    speed = speed - 65536.0
                }

                speed = abs(speed) / 100.0
                //let speed = Double(Int(block[5]) * 256 + Int(block[4]))
                outarr.append((WheelTrack.WheelValue.Speed, date, speed))
                
                //let temperature = Double(Int(buffer[12]) * 256 + Int(buffer[13])) / 100.0 // Very strange conversion in Kevin program
                
                
                // let temperature = Double(Int(buffer[12]) * 256 + Int(buffer[13])) / 340.0 + 35.0 // Very strange
                
                var intValue = Int(buffer[12]) * 256 + Int(buffer[13])
                
                if intValue >= 32768 {
                    intValue = intValue - 65536
                }
                
                let temperature = Double(intValue) / 340.0 + 35.0 // Seems 0 value is around 35ºC
            
                outarr.append((WheelTrack.WheelValue.Temperature, date, temperature))
                
                var distance = Double(Int(buffer[8]) * 256 + Int(buffer[9]))
                outarr.append((WheelTrack.WheelValue.Distance, date, distance))
                
                if let sd = startDistance{
                    distance = distance - sd
                } else {
                    startDistance = distance
                    distance = 0.0
                }

                
                let voltage = Double(Int(buffer[2]) * 256 + Int(buffer[3])) / 100.0
                outarr.append((WheelTrack.WheelValue.Voltage, date, voltage))
                
                //TODO: Aclarir el significat del signe. Sembla que no a totes les Gotway es igual. Mirar de provar
                // amb varies rodes
                
                var current = Double(Int(buffer[10]) * 256 + Int(buffer[11]))   // Comprovar signe Ojo. Sembla
                
                if current >= 32768.0 {
                    current = current - 65536.0
                }
                
                current = fabs(current / 100.0) // I have problems with sign in some wheels
                outarr.append((WheelTrack.WheelValue.Current, date, current))
                
                outarr.append((WheelTrack.WheelValue.Duration, date, 0.0))

                
                // filter voltage to get average voltage for battery level
                
                if voltageArray.count > NVoltageSamples {
                    let v0 = voltageArray.removeFirst()
                    
                    
                    acumVoltage = acumVoltage - v0
                    
                } else {
                    voltageArray.append(voltage)
                    acumVoltage += voltage
                }
                
                let avgVoltage = acumVoltage / Double(voltageArray.count)
                var battery = 0.0
                // Compute battery from average voltage
                
                if (avgVoltage < 52.9) {
                    battery = 0.0;
                } else if (avgVoltage >= 65.8) {
                    battery = 100.0;
                } else {
                    battery = (avgVoltage - 52.9) / 13.0 * 100.0;
                }
                
                outarr.append((WheelTrack.WheelValue.Battery, date, battery))
                buffer.removeAll()
                
                
                break

            
        default:
            break
            
            
        }
        return outarr
    }
    
    
    
    
}

//MARK: BLEWheelAdapterProtocol Extension

extension GotawayAdapter : BLEWheelAdapterProtocol{
    
    
    func wheelName() -> String {
        return "Gotaway"
    }
    
    
    // Hem de possar quelcom per diferenciar-lo del Ninebot!!!
    
    func isComptatible(services : [String : BLEService]) -> Bool{
        
        if let srv = services["FFE0"], let _ = services["180A"], services["1805"] == nil{
            if let chr = srv.characteristics["FFE1"]  {
                if chr.flags == "rxn"{
                    return true
                }
            }
        }
        
        return false
    }
    
    
    func startRecording(){
        
        startDistance = nil
        
        buffer.removeAll()
        
        
    }
    
    func stopRecording(){
        buffer.removeAll()
    }
    
    
    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        // OK, subscribe to characteristif FFE1
        
        connection.subscribeToChar("FFE1")
        
        let database = WheelDatabase.sharedInstance
        let uuid = peripheral.identifier.uuidString
        
        if let wh = database.getWheelFromUUID(uuid: uuid){
            self.wheel = wh
            
        } else {
            self.wheel = Wheel(uuid: uuid, name: self.name)
            wheel!.brand = "Gotway"
            wheel!.password = "000000"
            database.setWheel(wheel: wheel!)
        }

        BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data: nil)
        
    }
    
    
    func deviceDisconnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        
    }
    
    func giveTime(_ connection: BLEMimConnection) {
        
    }

    
    func charUpdated(_ connection: BLEMimConnection,  char : CBCharacteristic, data: Data) -> [(WheelTrack.WheelValue, Date, Double)]?{
        
        self.appendToBuffer(data)
        return self.procesaBuffer(connection)
    }
    
    
    func getName() -> String{
        return self.name
    }
    
    func getVersion() -> String{
        
        return "1.0"
    }
    
    func getSN() -> String{
        return self.serial
    }
    
    func getRidingLevel() -> Int{
        return 0
    }
    
    func getMaxSpeed() -> Double {
        return 20.0
    }

    
    func setDefaultName(_ name : String){
        self.name = name
    }
    
    func setDrivingLevel(_ level: Int){
        
    }
    func setLights(_ level: Int) {   // 0->Off 1->On....
    }
    func setLimitSpeed(_ speed : Double){
    }
    func enableLimitSpeed(_ enable : Bool)   {   // Enable or disable speedLimit
    }
    func lockWheel(_ lock : Bool){ // Lock or Unlock wheel
    }

}


