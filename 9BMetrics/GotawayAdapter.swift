//
//  GotawayAdapter.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 3/10/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//


import Foundation
import CoreBluetooth

class GotawayAdapter : NSObject {
    
    var headersOk = false
    
    var buffer : [UInt8] = []
    var voltageArray : [Double] = []
    var acumVoltage : Double = 0.0
    
    let NVoltageSamples = 10
    
    var name = "Gotaway"
    var serial = "12345"
    
    
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
            
            
            let totalDistance = Double( (Int(buffer[6]) * 256 + Int(buffer[7]))*65536 + (Int(buffer[8]) * 256 + Int(buffer[9])))
            outarr.append((WheelTrack.WheelValue.AcumDistance, date, totalDistance))
            
            buffer.removeAll()
            break
            
        case 20:
                let speed = Double(Int(buffer[4]) * 256 + Int(buffer[5]))
                //let speed = Double(Int(block[5]) * 256 + Int(block[4]))
                outarr.append((WheelTrack.WheelValue.Speed, date, speed))
                
                let temperature = Double(Int(buffer[12]) * 256 + Int(buffer[13])) / 100.0 // Very strange conversion in Kevin program
                outarr.append((WheelTrack.WheelValue.Temperature, date, temperature))
                
                let distance = Double(Int(buffer[8]) * 256 + Int(buffer[9]))
                outarr.append((WheelTrack.WheelValue.Distance, date, distance))
                
                let voltage = Double(Int(buffer[2]) * 256 + Int(buffer[3])) / 100.0
                outarr.append((WheelTrack.WheelValue.Voltage, date, voltage))
                
                
                let current = Double(Int(buffer[10]) * 256 + Int(buffer[11])) / 100.0  // Comprovar signe
                outarr.append((WheelTrack.WheelValue.Current, date, current))
                
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
        
        if let srv = services["FFE0"], let _ = services["180A"]{
            if let chr = srv.characteristics["FFE1"]  {
                if chr.flags == "rxn"{
                    return true
                }
            }
        }
        
        return false
    }
    
    
    func startRecording(){
        
        buffer.removeAll()
        
        
    }
    
    func stopRecording(){
        buffer.removeAll()
    }
    
    
    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        // OK, subscribe to characteristif FFE1
        
        connection.subscribeToChar("FFE1")
        
    }
    
    
    func deviceDisconnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        
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
}


