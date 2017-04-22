//
//  KingSongAdapter.swift
//
//  Seems it works OK with Rockwheel and others
//
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
import GyrometricsDataModel

class KingSongAdapter : NSObject {
    
    var headersOk = false
    
    var buffer : [UInt8] = []
    var voltageArray : [Double] = []
    var acumVoltage : Double = 0.0
    
    let NVoltageSamples = 10
    
    var name = "Kingsong"
    var serial = ""
    
    var wheel : Wheel?
    let distanceCorrection = 1.0 //0.791627219
    
    let writeChar = "FFE1"
    let readChar = "FFE1"
    
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
    
    func voltageToBatterylevel(_ volts : Double, wheelName : String) -> Double {
        
        var batt = 0.0
        
        if wheelName.hasPrefix("ROCK"){  // Taula presa de InMotion. Realment es molt mes senzilla de lo que sembla i si hp fessim lineal la diff es petita
            
            if volts >= 83.50 {
                batt = 1.0
            }else if volts > 80.0{
                batt = ((volts - 80.0) / 3.5) * 0.2 + 0.8
            }else if volts > 77.0{
                batt = ((volts - 77.0) / 3.0) * 0.2 + 0.6
            }else if volts > 74.0{
                batt = ((volts - 74.0) / 3.0) * 0.2 + 0.4
            }else if volts > 71.0{
                batt = ((volts - 71.0) / 3.0) * 0.2 + 0.2
            }else if volts > 55.0{
                batt = ((volts - 55.0) / 16.0) * 0.2
            }else {
                batt = 0.0
            }
        }else{
            
            
            if (volts < 50.0) {
                batt = 0.0
            } else if (volts >= 66.0) {
                batt = 1
            } else {
                batt = (volts - 50.0) / 16.0
            }
        }
        
        return batt * 100.0
        
    }
    
    // Here we process received information.
    // We maintain a buffer (buffer) and data is appended in appendToBuffer
    // as each block is received. Logical Data may span more than one block and not be aligned.
    //
    //
    //  So we call procesaBuffer to extract any posible data. It is returned as an array of
    //  3 values, the variable, the date and the value all aready converted to ggeneric values
    // and SI units
    
    // KingSong sends buffers containing all the information in one buffer
    
    func procesaBuffer(_ connection: BLEMimConnection) -> [(WheelTrack.WheelValue, Date, Double)]?
    {
        // Wait till header. We wait till we find a 0x55
        
        
        var outarr : [(WheelTrack.WheelValue, Date, Double)] = []
        
        while buffer.count > 0 && buffer[0] != 0xAA {
            buffer.removeFirst()
        }
        
        // Following character must be 0xaa, if not is noise
        
        
        if buffer.count < 10{    // Wait for more data
            return outarr
        }
        
        if buffer[1] != 0x55 {  // Fals header. continue cleaning
            
            return outarr
        }
        
        let date = Date()
        let block = Array(buffer)
        // We have 20 bytes and 10 bytes buffers
        
        switch(buffer.count){
            
        case 10:
            
            
            let totalDistance = Double( (Int(buffer[9]) * 256 + Int(buffer[8]))*65536 + (Int(buffer[7]) * 256 + Int(buffer[6]))) * distanceCorrection
            outarr.append((WheelTrack.WheelValue.AcumDistance, date, totalDistance))
            
            if let wh = self.wheel {
                wh.totalDistance = totalDistance
                WheelDatabase.sharedInstance.setWheel(wheel: wh)
            }
            
            buffer.removeAll()
            break
            
        case 20:
            switch(buffer[16]){
                
            case 169:
                let speed = Double(Int(buffer[5]) * 256 + Int(buffer[4])) / 360.0  * distanceCorrection // Ajusta precissio i km/h a m/s
                //let speed = Double(Int(block[5]) * 256 + Int(block[4]))
                outarr.append((WheelTrack.WheelValue.Speed, date, speed))
                
                let temperature = Double(Int(buffer[13]) * 256 + Int(buffer[12])) / 100.0 // Very strange conversion in Kevin program
                outarr.append((WheelTrack.WheelValue.Temperature, date, temperature))
                
                let totalDistance = Double( ((Int(buffer[7]) * 256 + Int(buffer[6])) * 256 + Int(buffer[9]) ) * 256 + Int(buffer[8])) * distanceCorrection
                outarr.append((WheelTrack.WheelValue.AcumDistance, date, totalDistance))
                
                let voltage = Double(Int(buffer[3]) * 256 + Int(buffer[2])) / 100.0
                outarr.append((WheelTrack.WheelValue.Voltage, date, voltage))
                
                var current = Double(Int(buffer[11]) * 256 + Int(buffer[10])) / 100.0
                
                if current >= 32768.0 {
                    current = current - 65536.0
                }
                
                current = fabs(current / 100.0) // I have problems with sign in some wheels
                
                outarr.append((WheelTrack.WheelValue.Current, date, current))
                
                // filter voltage to get average voltage for battery level
                
                if voltageArray.count > NVoltageSamples {
                    let v0 = voltageArray.removeFirst()
                    
                    
                    acumVoltage = acumVoltage - v0
                    
                } else {
                    voltageArray.append(voltage + current * 0.10)
                    acumVoltage += (voltage + current * 0.10)
                }
                
                let avgVoltage = acumVoltage / Double(voltageArray.count)
                
                let battery = voltageToBatterylevel(avgVoltage, wheelName: name)
                
                
                /* Gotaway
                 
                 if voltage <= 52.90 {
                 battery = 0.0
                 }else if (voltage >= 65.80){
                 battery = 100.0
                 }else {
                 battery = ((voltage - 52.90) / 13.0) * 100.0
                 }
                 */
                
                if let wh = self.wheel {
                    wh.totalDistance = totalDistance
                    WheelDatabase.sharedInstance.setWheel(wheel: wh)
                }
                
                
                outarr.append((WheelTrack.WheelValue.Battery, date, battery))
                buffer.removeAll()
                
                
                break
                
            case 185:
                var distance = Double( (Int(buffer[3]) * 256 + Int(buffer[2]))*65536 + (Int(buffer[5]) * 256 + Int(buffer[4]))) * distanceCorrection
                
                // Just to correct following case :
                // Start wheel and begin running
                // After a while connect to the wheel
                // Distance is from the start of the wheel. Now here we correct it to the moment we connect
                
                if let sd = startDistance{
                    distance = distance - sd
                } else {
                    startDistance = distance
                    distance = 0.0
                }
                
                outarr.append((WheelTrack.WheelValue.Distance, date, distance))
                
                let time = Double(Int(buffer[7]) * 256 + Int(buffer[6]))
                outarr.append((WheelTrack.WheelValue.Duration, date, time))
                
            case 187:
                var lname = ""
                
                var i = 2
                
                while i < 14 && block[i] != 0{
                    lname.append(Character(UnicodeScalar(block[i])))
                    
                    i += 1
                }
                
                self.name = lname
                
                if let wh = self.wheel {
                    wh.name = self.name
                    WheelDatabase.sharedInstance.setWheel(wheel: wh)
                }
                
                if lname.hasPrefix("ROCK"){
                    BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)
                }
                
                
                askSerial(connection)
                
            case 179:
                
                var lserial = ""
                var i = 2
                
                while i < 14 {
                    lserial.append(Character(UnicodeScalar(block[i])))
                    i += 1
                }
                
                i = 17
                while i < 20 {
                    lserial.append(Character(UnicodeScalar(block[i])))
                    i += 1
                }
                self.serial = lserial
                
                
                if let wh = self.wheel {
                    wh.serialNo = self.serial
                    WheelDatabase.sharedInstance.setWheel(wheel: wh)
                }
                
                BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)
                
            default:
                break
                
            }
            
            
        default:
            break
            
            
        }
        return outarr
    }
}

//MARK: BLEWheelAdapterProtocol Extension

extension KingSongAdapter : BLEWheelAdapterProtocol{
    
    
    func wheelName() -> String {
        return name
    }
    
    
    // Hem de possar quelcom per diferenciar-lo del Ninebot!!!
    
    func isComptatible(services : [String : BLEService]) -> Bool{
        
        if let srv = services["FFE0"], let _ = services["FFF0"] , let _ = services["180A"]{
            if let chr = srv.characteristics[writeChar]  {
                if chr.flags == "rxn"{
                    return true
                }
            }
        }
        
        return false
    }
    
    
    func startRecording(){
        buffer.removeAll()
        startDistance = nil
    }
    
    func stopRecording(){
        buffer.removeAll()
    }
    
    func askName(_ connection: BLEMimConnection, peripheral : CBPeripheral){
        // Write buffer
        
        var command : [UInt8] = Array(repeating: 0, count: 20)
        
        command[0] = 170
        command[1] = 85
        command[16] = 155
        command[17] = 20
        command[18] = 90
        command[19] = 90
        
        let data = Data(bytes: UnsafePointer<UInt8>(command), count: command.count)
        
        connection.writeValue(writeChar, data : data)
        
    }
    
    func askSerial(_ connection: BLEMimConnection){
        // Write buffer
        
        var command : [UInt8] = Array(repeating: 0, count: 20)
        
        command[0] = 170
        command[1] = 85
        command[16] = 99
        command[17] = 20
        command[18] = 90
        command[19] = 90
        
        let data = Data(bytes: UnsafePointer<UInt8>(command), count: command.count)
        
        connection.writeValue(writeChar, data : data)
        
    }
    
    func playHorn(_ connection: BLEMimConnection){
        var command : [UInt8] = Array(repeating: 0, count: 20)
        
        command[0] = 170
        command[1] = 85
        command[16] = 136
        command[17] = 20
        command[18] = 90
        command[19] = 90
        
        let data = Data(bytes: UnsafePointer<UInt8>(command), count: command.count)
        
        connection.writeValue(writeChar, data : data)
    }
    
    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        // OK, subscribe to characteristif writeChar
        
        connection.subscribeToChar(readChar)
        askName(connection, peripheral: peripheral)
        
        let database = WheelDatabase.sharedInstance
        let uuid = peripheral.identifier.uuidString
        
        if let wh = database.getWheelFromUUID(uuid: uuid){
            self.wheel = wh
            
        } else {
            self.wheel = Wheel(uuid: uuid, name: self.name)
            wheel!.brand = "KingSong"
            wheel!.password = "000000"
            database.setWheel(wheel: wheel!)
        }
        
        
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


